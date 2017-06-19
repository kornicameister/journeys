# Some useful notes about k8s usage

## Setting up k8s

```sh
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.19.1/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

## Listing all running pods

```sh
kubectl get pods --all-namespaces
```

## Adding dashboard

Dashboard for **k8s** is located [here](k8s_dashboard) and best option
to have/use it is to follow their documentation.

[k8s_dashboard]: https://github.com/kubernetes/dashboard
