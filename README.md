# k8s-in-k8s

Helm Charts based on Kind project (https://kind.sigs.k8s.io/) 
This set of charts will deploy a separate Kubernetes cluster (POD) inside of your Kubernetes cluster.
To get the kubeconfig file just curl POD-IP.
Services can be exposed with nodePort. Right now there are 3 available 30001-30003.
