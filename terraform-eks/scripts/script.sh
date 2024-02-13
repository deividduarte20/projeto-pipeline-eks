#!/bin/bash

# Install nginx Ingress Controller in AWS
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml

# Install repo helm prometheus-stack
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Install prometheus-stack and create namespace
# helm install prometheus prometheus-community/prometheus-stack --namespace monitoramento --create-namespace

# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml