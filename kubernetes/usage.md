# k8s

### Setting up k8s with minikube

```sh
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.19.1/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

or, and even better:
```sh
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

And to make it happen:
```sh
minikube stop ; minikube remove ; minikube start
```

### Setting up k8s with kubeadm

Check official docs as how to install that. 
See [here](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm)

```sh
apt-get purge kubelet kubeadm kubectl -y && \
snap remove kubectl && \
snap install kubectl --classic && \
apt-get install -y kubelet kubeadm
```

At the moment bootstraping kubeadm is possible.
Make it with ```--pod-network-cidr``` to be able to use
[Flannel](https://github.com/coreos/flannel/blob/master/Documentation/kube-flannel.yml).
After command is executed, look for instruction at the bottom

Run as root:

```sh
kubeadm reset
kubeadm init --pod-network-cidr=10.244.0.0/16
echo "Follow shit from output"
```

Run as normal user to enable local dev environment with just **master**:
```sh
kubectl taint nodes --all node-role.kubernetes.io/master-
```

#### Rememeber about Flannel dude

```sh
kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel-rbac.yml
```

## Listing all running pods

```sh
kubectl get pods --all-namespaces
```

## Adding dashboard

Dashboard for **k8s** is located [here](k8s_dashboard) and best option
to have/use it is to follow their documentation.

[k8s_dashboard]: https://github.com/kubernetes/dashboard
