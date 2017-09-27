#!/bin/bash

set +x

source $PWD/util.sh

post_credentials() {
    mkdir -p $HOME/.kube
    sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

post_taint() {
    kubectl taint nodes --all node-role.kubernetes.io/master-
}

post_flannel() {
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel-rbac.yml
}

post_init() {
    post_credentials
    post_taint
    post_flannel
}

init() {
    sudo -EH kubeadm reset
    sudo -EH kubeadm init --pod-network-cidr=10.244.0.0/16
    post_init
}

install() {
    if ! is_app_installed kubeadm ; then
        install_kubeadm
    fi
}

install_dashboard() {
    kubectl apply -f \
        https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
}

init_helm () {
    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule \
        --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl patch deploy --namespace kube-system tiller-deploy \
        -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
    helm init --upgrade --service-account=kubernetes-dashboard
}

install_helm() {
    curl -Lo get_helm.sh https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get
    chmod +x ./get_helm.sh
    bash ./get_helm.sh
    rm -rf ./get_helm.sh
    init_helm
}

install
init
install_dashboard
install_helm

sleep 15 && echo "Everything should be peachy"
kubectl get pods --all-namespaces

set -x
