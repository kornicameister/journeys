# -*- mode: ruby -*-
# vi: set ft=ruby :

IP_ADDR="192.168.6.25"

KOLLA_VIP_INTERNAL='10.0.2.33'
KOLLA_VIP_EXTERNAL=IP_ADDR.gsub('25','33')

VM_CPUS=6
VM_MEM=16384

FORWARD_PORTS = [
    [80, 8080],    # horizon
    [5000, 15000], # keystone 5000
    [5601, 15601], # kibana
    [9200, 19200], # elasticsearch
    [3000, 13000], # grafana
]

# IPs in here are related to kolla's internal and external VIPs
NO_PROXY = [KOLLA_VIP_INTERNAL, '10.0.2.15', IP_ADDR, KOLLA_VIP_EXTERNAL]

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.box_check_update = true
  config.cache.scope = :box if Vagrant.has_plugin?("vagrant-cachier")
  config.timezone.value = :host if Vagrant.has_plugin?('vagrant-timezone')

  if Vagrant.has_plugin?("vagrant-proxyconf")
    if ENV["http_proxy"]
      config.proxy.http = ENV["http_proxy"]
    end
    if ENV["https_proxy"]
      config.proxy.https = ENV["http_proxy"]
    end
    if ENV["no_proxy"]
      config.proxy.no_proxy = ENV["no_proxy"] + ',' + NO_PROXY.join(',')
    end
  end

  config.vm.define "vagrant" do |c|

      c.vm.hostname = "vagrant"
      c.vm.network "private_network", ip: "#{IP_ADDR}"

      FORWARD_PORTS.each {
          |x| c.vm.network "forwarded_port", guest: x[0], host_ip: '127.0.0.1', guest_ip: '192.168.6.33', host: x[1]
      }

      c.vm.provider "virtualbox" do |vb|
        vb.gui = false
        vb.memory = VM_MEM
        vb.cpus = VM_CPUS
      end

      # c.vm.provision :hosts do |provision|
      #   provision.add_localhost_hostnames = true
      #   provision.add_host "192.168.33.10", ["vagrant.vm"]
      #   provision.add_host "192.168.33.10", ["vagrant"]
      # end

      c.vm.synced_folder "~/", "/vagrant_home"
      c.vm.synced_folder "~/dev/kolla", "/home/vagrant/kolla"
      c.vm.synced_folder "~/dev/kolla-ansible", "/home/vagrant/kolla-ansible"

      c.vm.provision "shell", privileged: false, inline: <<-SHELL
         _XTRACE_KOLLA=$(set +o | grep xtrace)
         set -o xtrace

         _ERREXIT_KOLLA=$(set +o | grep errexit)
         set -o errexit

         prepare_system() {
             sudo -EH apt-get update
             sudo -EH apt-get install -y build-essential python-dev libffi-dev gcc libssl-dev sshpass
             sudo -EH apt-get purge -y python-pip docker docker-engine
         }

         get_pip() {
             curl -f --proxy $http_proxy --retry 6 \
                --retry-delay 5 \
                -o get-pip.py https://bootstrap.pypa.io/get-pip.py
             sudo -EH python get-pip.py
             pip --version
         }

         install_python_stuff() {
             sudo -EH pip install -U pip virtualenv setuptools python-openstackclient
         }

         install_kolla_in_dev_mode() {
             sudo -EH pip install -U pip docker-py
             (
                cd /home/vagrant/kolla ;
                git fetch --all ;
                git rebase github/master ;
                sudo -EH pip install -r requirements.txt ;
                sudo -EH python setup.py install
             )
             (
                cd /home/vagrant/kolla-ansible ;
                git fetch --all ;
                git rebase github/master ;
                sudo -EH pip install -r requirements.txt ;
                sudo -EH python setup.py install
             )
             sudo -EH pip install -U ansible
         }

         setup_kolla_work_dir() {
             mkdir -p /home/vagrant/kolla-run-me-from
             sudo -EH cp -r /home/vagrant/kolla-ansible/etc/kolla /etc/kolla/
             cp -r kolla-ansible/ansible/inventory/* /home/vagrant/kolla-run-me-from

             sudo -EH sed -e '
                s|10\.10\.10\.254|#{KOLLA_VIP_INTERNAL}|g;
                s|#kolla_external_vip_address:\s"{{\skolla_internal_vip_address\s}}"|kolla_external_vip_address: #{KOLLA_VIP_EXTERNAL}|g;
                s|#network_interface:\s"eth0"|network_interface: enp0s3|g;
                s|#kolla_external_vip_interface:\s"{{\snetwork_interface\s}}"|kolla_external_vip_interface: enp0s8|g;
             ' -i /etc/kolla/globals.yml
         }

         function kolla_pwd() {
            pushd /home/vagrant/kolla-run-me-from
            sudo -EH kolla-genpwd
            popd
         }

         function kolla_bootstrap_servers() {
            pushd /home/vagrant/kolla-run-me-from
            sudo -EH kolla-ansible bootstrap-servers -i all-in-one -vvvv
            popd
         }

         function kolla_upgrade_docker() {
             if [ #{ENV['NEW_DOCKER']} -eq 1 ];then
                 echo "uninstall provided docker to get newest one"
                 sudo -EH apt-get purge docker docker-engine -y
                 curl -sSL https://get.docker.io | bash
                 sudo -EH systemctl enable docker || true
             fi

             sudo -EH groupadd docker || true
             sudo -EH usermod -aG docker $USER || true
             echo "docker info" && sudo -EH docker info

             sudo -EH touch /etc/systemd/system/docker.service.d/proxy.conf
             sudo -EH chown vagrant:vagrant /etc/systemd/system/docker.service.d/proxy.conf
             echo "docker_proxy" && cat > /etc/systemd/system/docker.service.d/proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=#{ENV['http_proxy']}"
Environment="HTTPS_PROXY=#{ENV['http_proxy']}"
EOF
             sudo -EH systemctl daemon-reload
             sudo -EH systemctl restart docker
         }

         function kolla_prechecks() {
            pushd /home/vagrant/kolla-run-me-from
            sudo -EH kolla-ansible prechecks -i all-in-one -vvvv
            popd
         }

         function kolla_build_images() {
            pushd /home/vagrant/kolla-run-me-from
            # NOTE(trebskit) building of some images may fail, therefore
            # we need || true at the end
            sudo -EH kolla-build --base centos --type binary --cache --debug || true
            popd
         }

         function kolla_deploy() {
            pushd /home/vagrant/kolla-run-me-from
            sudo -EH kolla-ansible deploy -i all-in-one -vvvv
            sudo -EH kolla-ansible post-deploy
            popd
         }

         function kolla_init() {
             source /etc/kolla/admin-openrc.sh
             pushd /usr/local/share/kolla-ansible
             yes 'test' | sudo -EH ./init-runonce
             popd
         }

         funciton test_instance() {
             source /etc/kolla/admin-openrc.sh
             openstack server create \
                --image cirros \
                --flavor m1.tiny \
                --key-name mykey \
                --nic net-id=584307ec-270e-46f6-9019-9945ede6108e \
                demo1
         }

         prepare_system
         get_pip
         install_python_stuff
         install_kolla_in_dev_mode
         setup_kolla_work_dir

         kolla_bootstrap_servers
         kolla_upgrade_docker
         kolla_pwd
         kolla_prechecks
         kolla_build_images
         kolla_deploy
         kolla_init

         $_ERREXIT_KOLLA
         $_XTRACE_KOLLA

       SHELL
  end

end
