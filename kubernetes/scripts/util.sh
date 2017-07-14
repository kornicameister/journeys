#!/bin/bash

set +x

is_app_installed() {
    local what=$1
    command -v ${what} >/dev/null 2>&1 || return 1
    return 0
}

install_kubeadm() {
    sudo -EH apt-get update -qq
    sudo -EH snap install kubectl --classic
    sudo -EH apt-get install kubelet kubeadm -qq -y
}

purge_kubeadm() {
    sudo -EH apt-get purge kubelet kubeadm kubectl -y -qq
    sudo -EH apt-get autoremove -y -qq
    sudo -EH snap remove kubectl
    sudo -EH systemctl daemon-reload
}

purge_helm () {
    rm -rf $HOME/.helm
}

purge_node () {
    NODE=$(kubectl get nodes -o name | tr '/' ' ' | awk '{print $2}')

    echo "Kicking out k8s from $NODE"

    kubectl drain $NODE --grace-period=5 --delete-local-data \
        --force --ignore-daemonsets && echo "Drained"
    kubectl delete node $NODE && echo "Deleted"

    kubectl get pods --all-namespaces
    sudo kubeadm reset && echo "Reseted"
    rm -rf $HOME/.kube && echo "Removed $HOME/.kube"
}

set -x
