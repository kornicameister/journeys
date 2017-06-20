#!/bin/bash

# https://stackoverflow.com/a/39398359/1396508
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        --ceph)
        WITH_CEPH=1
        ;;
        --heat)
        WITH_HEAT=1
        ;;
        --magnum)
        WITH_MAGNUM=1
        ;;
        *)
        # Do whatever you want with extra options
        echo "Unknown option '$key'"
        ;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done

sudo apt-get update
sudo apt-get -y install git
git clone https://git.openstack.org/openstack-dev/devstack \
    --branch master \
    --depth 1 \
    --progress \
    --verbose

if [ $http_proxy ]; then
  git config --global url.https://git.openstack.org/.insteadOf git://git.openstack.org/
  sudo git config --global url.https://git.openstack.org/.insteadOf git://git.openstack.org/

  protocol=`echo $http_proxy | awk -F: '{print $1}'`
  host=`echo $http_proxy | awk -F/ '{print $3}' | awk -F: '{print $1}'`
  port=`echo $http_proxy | awk -F/ '{print $3}' | awk -F: '{print $2}'`

  echo "<settings>
          <proxies>
              <proxy>
                  <id>$host</id>
                  <active>true</active>
                  <protocol>$protocol</protocol>
                  <host>$host</host>
                  <port>$port</port>
              </proxy>
          </proxies>
         </settings>" > ./maven_proxy_settings.xml

  mkdir ~/.m2
  cp ./maven_proxy_settings.xml ~/.m2/settings.xml

  sudo mkdir /root/.m2
  sudo cp ./maven_proxy_settings.xml /root/.m2/settings.xml
fi

if [ -d "/tmp/vagrant-cache" ]; then
    if [ -d "/tmp/vagrant-cache/downloads" ]; then
      echo "Restoring downloads"
      cp /tmp/vagrant-cache/downloads/* devstack/files
    fi
    if [ -f "/tmp/vagrant-cache/pip-cache.tar.gz" ]; then
      echo "Restoring ~/.cache"
      tar xzf /tmp/vagrant-cache/pip-cache.tar.gz -C ~
    fi
    if [ -f "/tmp/vagrant-cache/nvm-cache.tar.gz" ]; then
      echo "Restoring ~/.nvm/.cache"
      mkdir -p ~/.nvm
      tar xzf /tmp/vagrant-cache/nvm-cache.tar.gz -C ~/.nvm
    fi
    if [ -f "/tmp/vagrant-cache/npm-pkgs.tar.gz" ]; then
      echo "Restoring ~/.npm"
      tar xzf /tmp/vagrant-cache/npm-pkgs.tar.gz -C ~
    fi
    if [ -f "/tmp/vagrant-cache/root-pip-cache.tar.gz" ]; then
      echo "Restoring ~root/.cache"
      sudo tar xzf /tmp/vagrant-cache/root-pip-cache.tar.gz -C ~root
    fi
    if [ -f "/tmp/vagrant-cache/root-m2-cache.tar.gz" ]; then
      echo "Restoring ~root/.m2"
      sudo tar xzf /tmp/vagrant-cache/root-m2-cache.tar.gz -C ~root
    fi
fi

cd devstack

echo '[[local|localrc]]

GIT_DEPTH=13
RECLONE=yes

SERVICE_HOST=192.168.10.69
HOST_IP=192.168.10.69
DATABASE_HOST=192.168.10.69
MYSQL_HOST=192.168.10.69
HOST_IP_IFACE=eth1

DATABASE_PASSWORD=secretdatabase
RABBIT_PASSWORD=secretrabbit
ADMIN_PASSWORD=secretadmin
SERVICE_PASSWORD=secretservice

LOGFILE=$DEST/logs/stack.sh.log
LOGDIR=$DEST/logs
LOG_COLOR=False

DEST=/opt/stack

# disable_all_services
enable_service horizon
enable_service tempest
enable_service zookeeper rabbit mysql key

# Nova options
VIRT_DRIVER="libvirt"

## Neutron options
Q_USE_SECGROUP=True
FLOATING_RANGE="192.168.10.0/24"
FIXED_RANGE="10.0.0.0/24"
Q_FLOATING_ALLOCATION_POOL=start=192.168.10.1240,end=192.168.10.254
PUBLIC_NETWORK_GATEWAY="192.168.10.1"
PUBLIC_INTERFACE=eth1

# Open vSwitch provider networking configuration
Q_USE_PROVIDERNET_FOR_PUBLIC=True
OVS_PHYSICAL_BRIDGE=br-ex
PUBLIC_BRIDGE=br-ex
OVS_BRIDGE_MAPPINGS=public:br-ex

# IMAGE URLS
IMAGE_URLS+=",https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img"
IMAGE_URLS+=",http://fedorapeople.org/groups/heat/prebuilt-jeos-images/F17-x86_64-cfntools.qcow2"

# SWIFT
SWIFT_HASH=66a3d6b56c1f479c8b4e70ab5c2000f5
SWIFT_REPLICAS=1

MONASCA_API_IMPLEMENTATION_LANG=${MONASCA_API_IMPLEMENTATION_LANG:-python}
MONASCA_PERSISTER_IMPLEMENTATION_LANG=${MONASCA_PERSISTER_IMPLEMENTATION_LANG:-python}
MONASCA_METRICS_DB=${MONASCA_METRICS_DB:-influxdb}

MONASCA_WITH_WSGI=No
MONASCA_API_USE_MOD_WSGI=$MONASCA_WITH_WSGI
MONASCA_LOG_API_USE_MOD_WSGI=$MONASCA_WITH_WSGI

MONASCA_TRANSFORM_BRANCH=master
MONASCA_LOG_API_BRANCH=master
MONASCA_API_BRANCH=master

MONASCA_LOG_API_REPO=https://git.openstack.org/openstack/monasca-log-api
MONASCA_API_REPO=https://git.openstack.org/openstack/monasca-api

# put test branches here
#
# put test branches here

# Uncomment one of the following lines and modify accordingly to enable the Monasca DevStack Plugin
enable_plugin monasca-api $MONASCA_API_REPO $MONASCA_API_BRANCH
enable_plugin monasca-log-api $MONASCA_LOG_API_REPO $MONASCA_LOG_API_BRANCH
# enable_plugin monasca-transform https://git.openstack.org/openstack/monasca-transform $MONASCA_TRANSFORM_BRANCH
' > local.conf

if [ "$WITH_HEAT" -eq 1 ]; then
    echo '# heat enabled
HEAT_BRANCH=master
enable_plugin heat https://github.com/openstack/heat $HEAT_BRANCH
    ' >> local.conf
fi

if [ "$WITH_MAGNUM" -eq 1 ]; then
    echo '# magnum enabled
MAGNUM_BRANCH=master
enable_plugin magnum https://github.com/openstack/magnum $MAGNUM_BRANCH
    ' >> local.conf
fi

if [ "$WITH_CEPH" -eq 1 ]; then
    echo '# ceph enabled
enable_plugin devstack-plugin-ceph https://github.com/openstack/devstack-plugin-ceph

ENABLE_CEPH_MANILA=True     # ceph backend for manila
ENABLE_CEPH_CINDER=True     # ceph backend for cinder
ENABLE_CEPH_GLANCE=True     # store images in ceph
ENABLE_CEPH_C_BAK=True      # backup volumes to ceph
ENABLE_CEPH_NOVA=True       # allow nova to use ceph resources
    ' >> local.conf
fi

echo "LET THE HELL BEGIN"
./stack.sh
echo "HELL IS DONE"

# Cache downloaded files for future runs
if [ -d "/tmp/vagrant-cache" ]; then
    mkdir -p /tmp/vagrant-cache/downloads
    cp files/*gz files/*.deb /tmp/vagrant-cache/downloads
    tar czf /tmp/vagrant-cache/pip-cache.tar.gz -C ~ .cache
    tar czf /tmp/vagrant-cache/nvm-cache.tar.gz -C ~/.nvm .cache
    tar czf /tmp/vagrant-cache/npm-pkgs.tar.gz -C ~ .npm
    sudo tar czf /tmp/vagrant-cache/root-pip-cache.tar.gz -C ~root .cache
    sudo tar czf /tmp/vagrant-cache/root-m2-cache.tar.gz -C ~root .m2
fi


