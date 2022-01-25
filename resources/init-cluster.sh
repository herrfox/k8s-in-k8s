#!/bin/sh

/usr/local/bin/dockerd-entrypoint.sh --tls=false &


# In case proxy is needed:
#export HTTP_PROXY="http://<set-your-proxy-ip>:<set-your-proxy-port>"
#export HTTPS_PROXY="${HTTP_PROXY}"
#export http_proxy="${HTTP_PROXY}"
#export https_proxy="${HTTP_PROXY}"
#export NO_PROXY="localhost, 127.0.0.1, docker"
#export no_proxy="${NO_PROXY}"

echo "${MY_POD_IP}"
apk update
apk add curl
apk add bridge
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod +x get_helm.sh
source ./get_helm.sh

#In case proxy is needed:
unset HTTPS_PROXY
unset HTTP_PROXY
unset http_proxy
unset https_proxy
unset NO_PROXY
unset no_proxy


cp /resources/config-template.yaml config-${NAME}.yaml
sed -i 's/HOST_IP/'"$MY_POD_IP"'/g'  config-${NAME}.yaml
echo "INFO Config temlate prepared"
echo "INFO Cluster installation started"
kind create cluster --name ${NAME} --config=config-${NAME}.yaml
while kubectl get nodes --no-headers| grep NotReady
do
    echo "Waiting 10 s for k8s cluster to be up"
    sleep 10
done
echo "INFO Cluster installation finished"
kubectl config view --flatten > k8s-config-${NAME}
echo "INFO Create Ingress"
kubectl apply -f resources/deploy.yaml
kubectl create cm index --from-file=index.html=k8s-config-${NAME}
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=240s
echo "INFO Create Ingress finished"
echo "INFO Exposing kubeconfig"
kubectl apply -f resources/config-app.yaml
kubectl wait --namespace default \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=config-app \
  --timeout=120s
echo "INFO Exposing finished"
sleep 5
echo "INFO Show kubernetes config file"
curl ${MY_POD_IP}

tail -f /dev/null
