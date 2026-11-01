# AWS EBS CSI Driver on K3s

This guide explains how to configure AWS EBS gp3 storage dynamically in a self-managed K3s Kubernetes cluster.

## 1. Architecture

- Kubernetes: K3s
- Storage provider: AWS EBS
- Volume type: gp3
- CSI driver: AWS EBS CSI Driver
- Provisioning: Dynamic
- Access mode: ReadWriteOnce
- Filesystem: ext4

## 2. Configure AWS IAM

1. Create an IAM role for EC2.
2. Attach the AWS EBS CSI permissions policy (`AmazonEBSCSIDriverPolicy`).
3. Attach the role to your EC2 instance through an instance profile.
4. Verify AWS credentials:

```bash
aws sts get-caller-identity
```

## 3. Configure EC2 Metadata

In EC2 → Instance → Actions → Instance settings → Modify instance metadata options:

- IMDS endpoint: Enabled
- IMDSv2: Required
- Metadata response hop limit: 2 (if using instance metadata credentials from controller pods)

Consider pod-level IAM isolation for production environments.

## 4. Install AWS EBS CSI Driver

Add the Helm repository:

```bash
helm repo add aws-ebs-csi-driver \
  https://kubernetes-sigs.github.io/aws-ebs-csi-driver

helm repo update
```

Create `ebs-csi-values.yaml`:

```yaml
controller:
  region: ap-south-1
  replicaCount: 1

node:
  hostNetwork: true
  kubeletPath: /var/lib/kubelet
```

Replace the region with your EC2 instance's actual region.

Install the driver:

```bash
helm upgrade --install aws-ebs-csi-driver \
  aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system \
  -f ebs-csi-values.yaml
```

## 5. Verify CSI Driver

```bash
kubectl get pods -n kube-system | grep ebs
kubectl get csidriver
kubectl get csinode
kubectl describe csinode
```

Expected CSI driver:

```text
ebs.csi.aws.com
```

## 6. Create StorageClass

Create `ebs-storageclass.yaml`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
allowVolumeExpansion: true
parameters:
  type: gp3
  encrypted: "true"
  fsType: ext4
```

Apply:

```bash
kubectl apply -f ebs-storageclass.yaml
kubectl get storageclass
```

## 7. Configure MongoDB StatefulSet

Use `volumeClaimTemplates` in the MongoDB StatefulSet:

```yaml
volumeClaimTemplates:
  - metadata:
      name: mongodb-persistent-storage-claim
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: ebs-gp3
      resources:
        requests:
          storage: 1Gi
```

Kubernetes automatically creates one PVC and one EBS volume for each StatefulSet replica.

## 8. Verify Dynamic Provisioning

```bash
kubectl get pvc -n voting-app-ns
kubectl get pv
kubectl get pods -n voting-app-ns -o wide
kubectl get volumeattachments
```

Finally, verify the newly created EBS volumes in:

AWS Console → EC2 → Elastic Block Store → Volumes.

## Important Notes

- No manually created PersistentVolumes are required.
- No local directory mapping or manual node affinity is required.
- Each MongoDB replica gets its own EBS volume.
- EBS volumes can only attach to compatible EC2 instances in the same Availability Zone.
- `ReadWriteOnce` does not mean that multiple pods on different nodes can share an EBS volume.
- `Retain` preserves the underlying EBS volume when its PVC is deleted.
- EBS provides persistent storage, not automatic multi-AZ replication or backup.

