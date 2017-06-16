![kolla_intro_image][kolla_intro_image]

# kolla-ansible investigation

**kolla-ansible** is a tool to manage deployment of containerized OpenStack
with the aid of ansible. In other words, using that to deploy only monasca
next to cloud that it will monitor is not exactly the use case of Kolla.

    That assumption was confirmed by one of the kolla members.

## Setup

Setup is really tricky and constrained by kolla-prechecks
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

## As development environment

**kolla* introduces development mode, where it will behave similar to
[devstack]. Here's the link to relevant [blueprint](kolla_mount_sources_bp).
This will be the best option (IMHO, looking at already implemented changes).

Other than that, it seems that it is possible to follow that path in more
manual way. This [build-openstack-from-source] part of kolla's documentation
shows that we can mount git repository and appropriate change from gerrit
for given container.

An example:

```ini
[monasca-api]
type=git
location=https://git.openstack.org/openstack/monasca-api
reference=refs/changes/20/473920/2
```

WARNING: This feature is somehow not working right now.
Guess someone (me <sick>) needs to send patch.

However, still we can mount all repositories into vagrant machine
or use kolla directly and build from sources using

```ini
[monasca-api]
type=local
location=/dev/monasca-api
```

NOTE: That does not require setting any references.
It purely reads the directory and install it.
Somehow similar to ```pip install /dev/monasca-api```.

## Community

### Status

Kolla seems to be quite active. There are new commits coming in and a lot of
blueprints.

* [all](https://blueprints.launchpad.net/kolla)
* [monasca](https://blueprints.launchpad.net/kolla?searchtext=monasca)

    Interestingly enough, containers for *kafka*, *zookeeper* were added
    as part of *monasca blueprint*

### Impact

Community has already shown the interest in having **monasca** inside
kolla. The oppurtunity lies there, just need to pick it up.

## Development effort<a name="dev_effort"></a>

Most of the job is already done by kolla, therefore writing containers and
"glue" layer in **kolla-ansible** seems to be the only effort needed.
Best to mention: once the "glue" part is done, all that needs to be done is
to maintain containers.

However, when it comes to binary containers, one would have to pay attention
to packages (RPMs or DEBs, depends on the distro containers is built on top of)

## Maintenance

See above in [Development effort](#dev_effort)

## Risks

### Non-python components

Putting in storm and it's topologies will require more effort as we need
to provide already clustered deployment that includes all storm components
(ui, nimbus, supervisor and logviewer). Not to mention of having
a one-shot container that will upload the required topologies and exit.

WARNING: Still the problem lies with topology itself. Where we should
compile that? Should we compile that at all inside container environment?
Most likely kolla's community will also want to have storm to support
more than just one topology. However that question lies unanswered.

### Development mode

Prior to implementing **development mode**, all the containers and ansible
layer must be developed first. It is hard to tell, if that requires providing
only **source** containers or also the other types (**rdo**, **binary**, etc.).

### Lack of certain containers/roles

For deploying **monasca**, first containers/roles for following components must
be implemented:

* kafka (container available [kafka_container])
* zookeeper (container available [zookeeper_container])

Other dependencies are available.

### Deploying next to existing cloud

*kolla* mission is to provide unified deployment mechanism of
containerized OpenStack as **entire cloud**. According to members of kolla,
it might not work well for cases, where something needs to be deployed next to
existing cloud.

The statement sound correct enough. That is based on the fact that **ansible**
is used as a coordinator. All the necessary information
(IPs, versions, networking etc) are part of *ansible variables* hence available
for all the *ansible roles*. A role is final entity that is responsible for
all sorts of operation on a container (regardless if that is starting or
stopping it).

Theoretically, and just in that way, it should (as ansible supports that) provide
another set of group and/or host variables where details how to connect
to exisitng cloud are set.


[kolla_mount_sources_bp]: https://blueprints.launchpad.net/kolla/+spec/mount-sources
[devstack]: https://github.com/openstack-dev/devstack
[kafka_container]: https://github.com/openstack/kolla/containers/kafka
[zookeeper_container]: https://github.com/openstack/kolla/containers/zookeeper
[kolla_intro_image]: https://image.slidesharecdn.com/containerclustering-pub-160530043919/95/managing-container-clusters-in-openstack-native-way-15-638.jpg?cb=1464583250
[kolla_image_building]: https://docs.openstack.org/developer/kolla/image-building.html
[graceful-upgrade]: https://blueprints.launchpad.net/kolla/+spec/graceful-upgrade
[kolla-upgrading]: https://docs.openstack.org/developer/kolla-ansible/operating-kolla.html#upgrading
[kolla-operating]: https://github.com/openstack/kolla-ansible/blob/master/doc/operating-kolla.rst
