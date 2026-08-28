# Standalone Prometheus (tar.gz) — Full Setup Reference

Covers installing Prometheus from the official tar.gz (not the Operator, not Helm) and wiring it up to scrape a Kubernetes cluster, in both deployment modes:

- **In-cluster**: Prometheus runs as a Pod inside the cluster (or on a node that's part of the cluster's network via `hostNetwork`)
- **Out-of-cluster**: Prometheus runs on a separate VM/host outside the cluster (your current setup — master node acting as an external box relative to K8s' internal DNS)

---

## 0. Core concept: why RBAC + tokens are even needed

Prometheus itself has no built-in Kubernetes auth. Every K8s-aware scrape target (kubelet, cAdvisor, apiserver, kube-state-metrics if secured) authenticates callers via **bearer tokens** tied to a **ServiceAccount**, and authorizes them via **RBAC** (ClusterRole + ClusterRoleBinding). So the flow is always:

```
ServiceAccount  →  ClusterRole (what it's allowed to read)  →  ClusterRoleBinding (attach role to SA)  →  Token (proof of identity)  →  prometheus.yml (uses token to auth)
```

kube-state-metrics is usually exposed unauthenticated on its own port (8080), so it often doesn't need this chain — only kubelet/cAdvisor (port 10250) and the apiserver do, since they're security-sensitive.

---

## 1. Install Prometheus from tar.gz (same for both modes)

```bash
PROM_VERSION=2.55.1   # check https://prometheus.io/download/ for current
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64

sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/prometheus.yml
```

**Run as a dedicated user (recommended over running as `ubuntu`/root):**
```bash
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```

**systemd unit** (`/etc/systemd/system/prometheus.service`):
```ini
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
```
`--web.enable-lifecycle` lets you do `curl -X POST http://localhost:9090/-/reload` instead of restarting the whole process on every config change — do this from the start, saves pain later.

---

## 2. Mode A — Prometheus OUTSIDE the cluster (your current setup)

Prometheus can't resolve `*.svc.cluster.local` DNS and can't reach ClusterIP services — it must hit **NodePort**, **LoadBalancer**, or a **node's own IP** for anything.

### 2.1 kube-state-metrics (usually no auth needed)

Expose via NodePort:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kube-state-metrics-nodeport
  namespace: kube-system
spec:
  type: NodePort
  selector:
    app.kubernetes.io/name: kube-state-metrics
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30080
```
```yaml
# prometheus.yml
  - job_name: "kube-state-metrics"
    static_configs:
      - targets: ["<any-node-ip>:30080"]
```

### 2.2 cAdvisor / kubelet metrics (auth required — port 10250, HTTPS)

**Step 1 — ServiceAccount + RBAC:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus-cadvisor
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-cadvisor
rules:
  - apiGroups: [""]
    resources: ["nodes/metrics", "nodes/proxy", "nodes/stats"]
    verbs: ["get"]
  - nonResourceURLs: ["/metrics", "/metrics/cadvisor"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-cadvisor
subjects:
  - kind: ServiceAccount
    name: prometheus-cadvisor
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: prometheus-cadvisor
  apiGroup: rbac.authorization.k8s.io
```

**Step 2 — Token.** On K8s 1.24+, don't rely on auto-populated Secrets — they can silently come back empty. Use `kubectl create token` directly:
```bash
kubectl -n kube-system create token prometheus-cadvisor --duration=8760h \
  | tr -d '\n' \
  | sudo tee /etc/prometheus/cadvisor-token > /dev/null

sudo chown prometheus:prometheus /etc/prometheus/cadvisor-token   # match whatever user runs Prometheus
sudo chmod 400 /etc/prometheus/cadvisor-token
```
- `tr -d '\n'` is not optional — a trailing newline in the token file is the single most common cause of an unexplained `401 Unauthorized`.
- `--duration=8760h` = 1 year. No auto-rotation with this method; note the expiry and regenerate before it lapses.
- File owner **must** match the OS user the Prometheus process runs as (`ps aux | grep prometheus` to confirm) — mismatched ownership = `permission denied` reading the file, not a K8s error at all.

**Step 3 — scrape config:**
```yaml
  - job_name: "kubernetes-cadvisor"
    scheme: https
    tls_config:
      insecure_skip_verify: true   # kubelet's serving cert usually isn't signed by a CA Prometheus trusts
    bearer_token_file: /etc/prometheus/cadvisor-token
    static_configs:
      - targets:
          - "<control-plane-ip>:10250"
          - "<worker-1-ip>:10250"
          - "<worker-2-ip>:10250"
    metrics_path: /metrics/cadvisor
    relabel_configs:
      - source_labels: [__address__]
        regex: '(.*):.*'
        target_label: node
        replacement: '${1}'
```
List every node explicitly — cAdvisor metrics are per-node/local to each kubelet, static out-of-cluster Prometheus has no service discovery to find them automatically.

**Step 4 — verify the auth chain independently before trusting Prometheus's own status:**
```bash
# Is the token itself valid?
TOKEN=$(cat /etc/prometheus/cadvisor-token)
kubectl create -f - <<EOF
apiVersion: authentication.k8s.io/v1
kind: TokenReview
spec:
  token: "$TOKEN"
EOF
# check status.authenticated == true

# Does the endpoint actually respond with that token?
curl -k -H "Authorization: Bearer $TOKEN" https://<node-ip>:10250/metrics/cadvisor | head
```

**Step 5 — reload:**
```bash
curl -X POST http://localhost:9090/-/reload
```
Check `http://<prometheus-host>:9090/targets` for `kubernetes-cadvisor` → `UP`.

### 2.3 Firewall/Security List note (recurring gotcha on cloud VPCs)

Any cloud (OCI Security Lists, AWS SGs, GCP firewall rules) that's default-deny will silently drop scrapes on 10250/30080/9100 even when RBAC and tokens are perfect. If a target shows `context deadline exceeded` or hangs rather than returning a clean 401/403, check the firewall before touching Kubernetes auth again — a hang is network-layer, a 401/403 is auth-layer.

---

## 3. Mode B — Prometheus INSIDE the cluster (as a Pod)

Inside the cluster, Prometheus can use `*.svc.cluster.local` DNS, mount a ServiceAccount token automatically (no manual token juggling), and use **Kubernetes service discovery (`kubernetes_sd_configs`)** instead of hardcoded static targets — this is the actual production pattern (what kube-prometheus-stack / the Operator does under the hood).

### 3.1 Deploy as a Pod with its own ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  - apiGroups: [""]
    resources: ["nodes", "nodes/proxy", "nodes/metrics", "services", "endpoints", "pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["extensions", "networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch"]
  - nonResourceURLs: ["/metrics", "/metrics/cadvisor"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: monitoring
roleRef:
  kind: ClusterRole
  name: prometheus
  apiGroup: rbac.authorization.k8s.io
```

### 3.2 No manual token file needed

When a Pod uses this ServiceAccount, Kubernetes auto-mounts a token at:
```
/var/run/secrets/kubernetes.io/serviceaccount/token
```
Reference it directly in `prometheus.yml` — no `create token`, no chown dance, and it auto-rotates (K8s refreshes it in the background, kubelet handles renewal transparently).

### 3.3 Scrape config using service discovery (not static IPs)

```yaml
scrape_configs:
  - job_name: "kubernetes-cadvisor"
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor

  - job_name: "kube-state-metrics"
    static_configs:
      - targets: ["kube-state-metrics.kube-system.svc.cluster.local:8080"]

  - job_name: "kubernetes-pods"
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      # only scrape pods with prometheus.io/scrape: "true" annotation
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```
Key differences from Mode A: `ca_file` is used instead of `insecure_skip_verify` (the in-cluster CA cert is trusted), targets route through the **apiserver's proxy** (`/api/v1/nodes/<node>/proxy/...`) rather than hitting kubelet directly, and `kubernetes_sd_configs` auto-discovers new nodes/pods — no manual IP list to maintain as the cluster scales.

### 3.4 Deploy Prometheus as a Pod (ConfigMap + Deployment)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    # paste scrape_configs from 3.3 here
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels: { app: prometheus }
  template:
    metadata:
      labels: { app: prometheus }
    spec:
      serviceAccountName: prometheus
      containers:
        - name: prometheus
          image: prom/prometheus:v2.55.1
          args:
            - "--config.file=/etc/prometheus/prometheus.yml"
            - "--web.enable-lifecycle"
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: config
              mountPath: /etc/prometheus
      volumes:
        - name: config
          configMap:
            name: prometheus-config
```
(This uses the container image rather than the tar.gz inside a Pod — if you specifically want the tar.gz binary in-cluster, bake it into a custom image via a minimal Dockerfile with the extracted binary + config, same net effect.)

---

## 4. Decision cheat-sheet: which mode to use

| | Out-of-cluster (tar.gz on a VM/master) | In-cluster (Pod) |
|---|---|---|
| DNS | No `.svc.cluster.local` — must use node IP:NodePort | Full cluster DNS |
| Auth | Manual token via `kubectl create token`, manual file mgmt | Auto-mounted SA token, auto-rotated |
| Target discovery | Static IPs, manually maintained | `kubernetes_sd_configs`, auto-discovers |
| TLS | `insecure_skip_verify: true` typical | `ca_file` (cluster CA trusted) |
| Firewall exposure | Every scrape port (10250, NodePorts) must be open across network boundary | No exposure needed — all traffic stays inside cluster network |
| Best for | Learning the internals, small/lab clusters, air-gapped monitoring host | Production — matches what kube-prometheus-stack does |

---

## 5. Common failure signatures (quick lookup)

| Symptom | Layer | Likely cause |
|---|---|---|
| Target `DOWN`, connection times out / hangs | Network | Firewall / Security List blocking the port |
| `401 Unauthorized` | Auth (API server rejected token) | Empty/corrupted token, trailing newline, expired token |
| `403 Forbidden` | Authz (RBAC) | Token valid but ClusterRole/Binding missing or wrong verbs/resources |
| `permission denied` reading token file | OS filesystem | Token file owner ≠ user running Prometheus process |
| Grafana panel shows N/A but Prometheus has the data | Grafana | Dashboard template variable (`$cluster`, `$job`) not resolving, or datasource mismatch |
| Grafana panel N/A, and query returns nothing in Prometheus too | Missing scrape job | Dashboard expects a metric source (commonly cAdvisor) you haven't configured |
| `roleRef` apply error / immutable field | kubectl | ClusterRoleBinding already exists — must `delete` before re-`apply`, can't patch roleRef |
