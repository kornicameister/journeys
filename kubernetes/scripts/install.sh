#!/bin/bash

set +x

source $PWD/util.sh

FORCE=$1

if [[ $FORCE == "--force" ]]; then
    purge_kubeadm
fi

if ! is_app_installed kubeadm ; then
    echo "Installing kubeadm"
    install_kubeadm
else
    echo "kubeadm is already here"
fi

set -x
