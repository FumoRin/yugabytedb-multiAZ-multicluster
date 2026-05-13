# YugabyteDB Multi-Cluster Deployment

This repository contains the configuration and manifests for deploying a multi-cluster YugabyteDB environment and a test application for verification.

## Architecture Overview

The setup consists of two primary Kubernetes clusters:
- **Atlas**: Region `id-atlas`, Zone `id-atlas-1`.
- **Orpheus**: Region `id-orpheus`, Zones `id-orpheus-1` and `id-orpheus-2`.

These clusters are connected using **Submariner** for cross-cluster networking, allowing YugabyteDB Masters and TServers to communicate across cluster boundaries using `.clusterset.local` DNS names. **Istio** is used as a service mesh to provide locality-aware load balancing and failover.

## Repository Structure

- `values.yaml`: Base Helm values for YugabyteDB.
- `atlas-1-helm-values.yaml`: Helm overrides for the Atlas cluster.
- `orpheus-1-helm-values.yaml`: Helm overrides for the first zone in the Orpheus cluster.
- `orpheus-2-helm-values.yaml`: Helm overrides for the second zone in the Orpheus cluster.
- `yb-unified-tserver.yaml`: Kubernetes Service and Istio DestinationRule for unified, cross-cluster TServer access.
- `cashflow-app.yaml`: Manifests for the "Cashflow" test application (Backend).
- `scale-up.sh` / `scale-down.sh`: Helper scripts to scale TServers across clusters.

## Prerequisites

1. Two Kubernetes clusters (`atlas` and `orpheus`) with Submariner installed.
2. Helm installed.
3. Istio installed on both clusters.
4. `kubectl` contexts named `atlas` and `orpheus`.

## Deployment Steps

### 1. Deploy YugabyteDB

Deploy the database to both clusters using the provided Helm values.

**On Atlas Cluster:**
```bash
helm install atlas-1 yugabytedb/yugabyte -f values.yaml -f atlas-1-helm-values.yaml -n yb-system
```

**On Orpheus Cluster:**
```bash
helm install orpheus-1 yugabytedb/yugabyte -f values.yaml -f orpheus-1-helm-values.yaml -n yb-system
helm install orpheus-2 yugabytedb/yugabyte -f values.yaml -f orpheus-2-helm-values.yaml -n yb-system
```

### 2. Configure Unified Service and Failover

Apply the unified TServer service and Istio failover rules:
```bash
kubectl apply -f yb-unified-tserver.yaml --context atlas
kubectl apply -f yb-unified-tserver.yaml --context orpheus
```

### 3. Deploy Test Application (Cashflow)

Deploy the application to the desired cluster:
```bash
kubectl apply -f cashflow-app.yaml --context atlas
```

## Operations

### Scaling

You can use the provided scripts to quickly scale the TServers:

- **Scale Up**: Sets TServers to 3 on Atlas and 2 on Orpheus.
  ```bash
  ./scale-up.sh
  ```
- **Scale Down**: Sets TServers to 0 on both clusters.
  ```bash
  ./scale-down.sh
  ```

## Verification

The Cashflow application connects to the database via the unified service `yb-unified-tserver.yb-system.svc.cluster.local:5433`. It is configured with health and readiness probes.

Access the application via the exposed Frontend's external IP, which is retrieved with `kubectl get svc -n cashflow-app`.
