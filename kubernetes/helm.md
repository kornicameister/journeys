# k8s Helm

## Installing

```sh
curl -Lo helm.tar.gz https://kubernetes-helm.storage.googleapis.com/helm-v2.4.2-linux-amd64.tar.gz && tar -zxvf helm.tar.gz && chmod +x linux-amd64/helm && sudo mv -f linux-amd64/helm /usr/local/bin/helm && rm -rf helm.tar.gz
```

or

```sh
curl -Lo get_helm.sh https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get && chmod +x get_helm.sh && ./get_helm.sh
```

and later on, enable it:

```sh
helm init
```

that will create some local files in the directory you're in.

For more information about using **helm** see [helm_quickstart]

[helm_quickstart]: https://github.com/kubernetes/helm/blob/master/docs/quickstart.md

## Where to find apps

Application that can be deployed using **helm** can be found at [kubeapps].

[kubeapps]: https://kubeapps.com/
