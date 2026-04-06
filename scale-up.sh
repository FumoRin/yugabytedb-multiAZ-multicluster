#!/bin/zsh

kubectl scale -n yb-system --context atlas statefulsets atlas-1-yb-tserver --replicas 3
kubectl scale -n yb-system --context orpheus statefulsets orpheus-1-yb-tserver --replicas 2
