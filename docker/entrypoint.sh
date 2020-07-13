#!/bin/sh

# reference: https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#accessing-the-api-from-a-pod
kubectl config set-cluster kubectl \
  --server=https://kubernetes.default.svc
kubectl config set-credentials kubectl \
  --token=/var/run/secrets/kubernetes.io/serviceaccount/token \
  --client-certificate=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

exec "$@"