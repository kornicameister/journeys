
#!/bin/bash

set +x

source $PWD/util.sh

purge_node
purge_kubeadm
purge_helm

set -x
