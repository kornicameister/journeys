![kolla_intro_image][kolla_intro_image]

# kolla-ansible investigation

**kolla-ansible** is a tool to manage deploymenet of containerized OpenStack
with the aid of ansible. In other words, using that to deploy only monasca
next to cloud that it will monitor is not exactly the use case of Kolla.

    That assumption was confirmed by one of the kolla members.

## Setup

Setup is really tricky and contrained by kolla-prechecks
```kolla-ansible prechecks```. Biggest problems encountered were related
network setup:

* having one or two interfaces (or more) to control the network traffic in/out
deployed nodes
* having full visibility in the network between nodes
* having *kolla_internal* and *kolla_external* addresses to be available
on different networks if the *kolla_internal_interface* and
*kolla_external_interface* differs

Another set of problems were presented by the proxy.
If proxy is part of an environment, a setup fo kolla has to be carefully
reviewed and all IPs that will be used to communicate has to be put into
```NO_PROXY``` environmental variable.

Example from [Vagrantfile](./Vagrantfile):

```ruby
PUBLIC_IP="192.168.6.25"

KOLLA_VIP_INTERNAL='10.0.2.33'
KOLLA_VIP_EXTERNAL=PUBLIC_IP.gsub('25','33')

NO_PROXY = [KOLLA_VIP_INTERNAL, '10.0.2.15', PUBLIC_IP, KOLLA_VIP_EXTERNAL]

if Vagrant.has_plugin?("vagrant-proxyconf")
    if ENV["no_proxy"]
      config.proxy.no_proxy = ENV["no_proxy"] + ',' + NO_PROXY.join(',')
    end
end
```

    Note that, best results in kolla (and in general containers) are
    obviously achievable while using no proxy internet access.

## Environments

*kolla* covers pretty much all the operating systems where it is possible
to run docker containers. After all, **kolla** aims at being deployment manager.

However, it is worth mentioning that it is possible to pick the *Linux Distro*
that will be used as a foundation for
single container: ```centos, rhel, ubuntu, oraclelinux, debian```. Not to
mention that it flawlessly supports building

More details about image building can be found here [kolla_image_building]

## In CI

Since *kolla* deploys OpenStack using containers, it is possible to use that
inside any CI setup as it will be lightweight and fast (once all the images
are downloaded).

Development of X application would require rebuilding selected images prior
to deployment. It is achievable through *docker* feature: **own docker registry**
that keeps all working/stable images and only upon marges new versions
(even using the same tag) will enter the registry replacing the old ones.

    Note that this description can be applied to each solution that is
    somehow based on docker, as long as it is an option to point at
    internal docker registry.

## Upgrading the components

For now, everything that could be found about upgrading components with kolla
drilled down to following blueprint(s) and wiki(s):

* [graceful-upgrade]
* [kolla-upgrading]
* [kolla-operating]

Each service and each container have own tag that allows to set the desired
version of what exactly we wish to deploy.

It is worth mentioning now that images can be **source** or **binary** type.
That basically means that we can control what tag (version) of correspnding
upstream repository will be used to create image.
In other words, let's take nova image and upstream [repo](https://github.com/openstack/nova).
There will be certain tags that we could take to build **source** image.
For **binary** everything depends on the packagers/owners of the repositories
that were used in build process.

## Scaling

Scalling with **kolla-ansible** is done via ansible. If there is a need
to scale up/down, one must provide modified inventory file and redeploy.

## As development

## Community impact

## Development effort

## Maintenance

## Risks


[kolla_intro_image]: https://image.slidesharecdn.com/containerclustering-pub-160530043919/95/managing-container-clusters-in-openstack-native-way-15-638.jpg?cb=1464583250
[kolla_image_building]: https://docs.openstack.org/developer/kolla/image-building.html
[graceful-upgrade](https://blueprints.launchpad.net/kolla/+spec/graceful-upgrade)
[kolla-upgrading](https://docs.openstack.org/developer/kolla-ansible/operating-kolla.html#upgrading
[kolla-operating](https://github.com/openstack/kolla-ansible/blob/master/doc/operating-kolla.rst)
