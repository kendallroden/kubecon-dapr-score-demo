#!/bin/bash
set -o errexit

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 31000
    hostPort: 80
    protocol: TCP
EOF

GATEWAY_API_VERSION=$(curl -sL https://api.github.com/repos/kubernetes-sigs/gateway-api/releases/latest | jq -r .tag_name)
kubectl apply \
    -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml

helm upgrade ngf oci://ghcr.io/nginxinc/charts/nginx-gateway-fabric \
    --install \
    --create-namespace \
    -n nginx-gateway \
    --set service.type=NodePort \
    --set-json 'service.ports=[{"port":80,"nodePort":31000}]'

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: default
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF

helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update
helm upgrade \
    dapr \
    dapr/dapr \
    --install \
    --create-namespace \
    -n dapr-system
    # Disabling because current issue with this https://github.com/dapr/dapr/blob/master/charts/dapr/charts/dapr_scheduler/templates/_helpers.tpl#L33C34-L33C51
    #--set dapr_scheduler.cluster.inMemoryStorage=true