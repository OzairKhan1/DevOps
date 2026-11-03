# K3s Host-Based Ingress — Key Points

## 1. Grafana

- Grafana can use host-based routing at `/` without a subpath configuration.
- If it was previously configured for a subpath such as `/grafana`, update its external URL and disable subpath serving.

For this setup:

```yaml
grafana:
  env:
    GF_SERVER_ROOT_URL: "http://grafana.k3s.test/"
    GF_SERVER_SERVE_FROM_SUB_PATH: "false"
```

Find the actual Grafana Secret name (it depends on the Helm release name):

```bash
kubectl get secrets -n monitoring | grep grafana
```

Then retrieve the credentials, replacing `<GRAFANA_SECRET_NAME>` with the Secret name found above:

```bash
kubectl -n monitoring get secret <GRAFANA_SECRET_NAME> \
  -o jsonpath='{.data.admin-user}' | base64 -d; echo

kubectl -n monitoring get secret <GRAFANA_SECRET_NAME> \
  -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

## 2. Prometheus

- Prometheus can be protected with Basic Authentication at the NGINX Ingress.
- Install `apache2-utils` and create an htpasswd file:

```bash
sudo apt install -y apache2-utils
htpasswd -c auth admin
```

- Create the Secret in the same namespace as the Prometheus Ingress. The file must be stored under the key `auth` for the community ingress-nginx default auth-file format:

```bash
kubectl -n monitoring create secret generic prom-basic-auth \
  --from-file=auth
```

- The Prometheus Ingress uses these annotations:

```yaml
nginx.ingress.kubernetes.io/auth-type: basic
nginx.ingress.kubernetes.io/auth-secret: prom-basic-auth
nginx.ingress.kubernetes.io/auth-realm: "Prometheus"
```

- Check the URL and path configured on the Prometheus custom resource:

```bash
kubectl get prometheus prometheus-stack-kube-prom-prometheus \
  -n monitoring \
  -o jsonpath='ExternalURL: {.spec.externalUrl}{"\n"}RoutePrefix: {.spec.routePrefix}{"\n"}'
```

For host-based routing at `/` in this local setup:

```yaml
prometheus:
  prometheusSpec:
    externalUrl: "http://prometheus.k3s.test/"
    routePrefix: "/"
```

## 3. Argo CD

For this HTTP lab setup, configure Argo CD to serve HTTP behind the Ingress Controller:

```bash
kubectl edit cm argocd-cmd-params-cm -n argocd
```

Add this under the existing `data` section:

```yaml
data:
  server.insecure: "true"
```

Then restart Argo CD Server:

```bash
kubectl rollout restart deployment argocd-server -n argocd
```

`server.insecure: "true"` is for this lab/reverse-proxy setup; do not expose Argo CD over unencrypted HTTP on a public network.

Retrieve the initial admin password (the Secret may no longer exist if initial setup has been completed):

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

## 4. Update Grafana and Prometheus Using Helm

Keep both applications' URL settings in a values file, for example `prometheus-local-values.yaml`:

```yaml
grafana:
  env:
    GF_SERVER_ROOT_URL: "http://grafana.k3s.test/"
    GF_SERVER_SERVE_FROM_SUB_PATH: "false"

prometheus:
  prometheusSpec:
    externalUrl: "http://prometheus.k3s.test/"
    routePrefix: "/"
```

Check the installed release and chart version:

```bash
helm list -n monitoring
```

Upgrade the existing release while preserving its other supplied values:

```bash
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --version <CHART_VERSION_ONLY> \
  --reuse-values \
  -f prometheus-local-values.yaml \
  --wait \
  --timeout 10m
```

Use only the version number with `--version` (for example, `92.14.0`), not the full chart label `kube-prometheus-stack-92.14.0`.

Verify the Prometheus settings:

```bash
kubectl get prometheus prometheus-stack-kube-prom-prometheus \
  -n monitoring \
  -o jsonpath='ExternalURL: {.spec.externalUrl}{"\n"}RoutePrefix: {.spec.routePrefix}{"\n"}'
```

## 5. NGINX Ingress Controller — Key Points

1. The Ingress Controller runs inside the Kubernetes cluster as one or more Pods, usually in its own namespace (in this setup: `ingress-nginx`).
2. An Ingress resource defines the routing rules. The Ingress Controller watches those resources and configures NGINX to route requests to Kubernetes Services.
3. An Ingress resource is namespace-scoped, and its backend Service must be in the same namespace. One YAML file can contain multiple Ingress resources from different namespaces, separated by `---`; each resource specifies its own namespace.
4. The controller must be exposed through a networking mechanism such as NodePort, HostPort, or a LoadBalancer Service. A cloud load balancer is not mandatory in every environment.
5. NodePort and HostPort are separate mechanisms. NodePort exposes a Service on a node port. HostPort binds a Pod's container port directly to a port on the node. One does not automatically create the other.

### Ports in the current k3s setup

| Exposure method | HTTP | HTTPS |
|---|---:|---:|
| NGINX Pod HostPort | 80 | 443 |
| NGINX Service NodePort | 30143 | 32132 |

The current NGINX Controller Deployment has `hostPort: 80` and `hostPort: 443`. This is why the hostnames work without an explicit port:

```text
http://grafana.k3s.test
https://grafana.k3s.test
```

The same controller Service also exposes NodePorts, so these URLs work when specifying the NodePort:

```text
http://grafana.k3s.test:30143
https://grafana.k3s.test:32132
```

### Some Famous Kubernetes Dashboards

| ID | Dashboard | Shows |
|---|---|---|
| 15757 | Kubernetes / Views / Global | Cluster-wide CPU, memory, network, and pod counts (the one most people start with). |
| 15758 | Kubernetes / Views / Namespaces | Per-namespace usage, so you can monitor `app-ns`. |
| 15760 | Kubernetes / Views / Pods | Per-pod CPU and memory against requests and limits. |
| 15759 | Kubernetes / Views / Nodes | Node-level metrics and resource utilization. |
| 1860 | Node Exporter Full | Detailed VM metrics: disk, network, load, and memory. |

**Recommendation:** Import dashboards `15757` and `1860` first.

**Note:** Dashboard IDs can change on Grafana.com, so verify that each dashboard loads correctly.
