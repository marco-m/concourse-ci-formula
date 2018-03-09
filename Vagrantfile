# Enforce minimum version both for Vagrant and VirtualBox.
Vagrant.require_version ">= 2.0.2"
MIN_VIRTUALBOX_VERSION = Gem::Version.new('5.2.8')
version = `VBoxManage --version`
clean_version = /[0-9]+\.[0-9]+\.[0-9]+/.match(version)
if Gem::Version.new(clean_version) < MIN_VIRTUALBOX_VERSION
    abort "Please upgrade to Virtualbox >= #{MIN_VIRTUALBOX_VERSION}"
end

# Set correct locale for `vagrant ssh`, no matter how the host is configured.
ENV["LC_ALL"] = "en_US.UTF-8"
# Disable escaping from current directory via symbolic links, new VirtualBox
# "feature" enabled by default.
ENV["VAGRANT_DISABLE_VBOXSYMLINKCREATE"] = "1"

vm_name = "concourse-formula"
Vagrant.configure("2") do |config|
  # Why not 16.04 LTS ? Because we want btrfs for performance and we need a
  # recent kernel to reduce the many bugs seen with Concourse and btrfs.
  config.vm.box = "bento/ubuntu-17.10"
  # NOTE same IP address must be passed to Concourse ATC, DO NOT USE loopback!
  # We specify "private_network" instead of just using the NAT done by VirtualBox
  # because if we use NAT then the value of the port forwarded for 8080 depends
  # on the current status of the host, while we want to be sure tha 8080 is
  # available.
  
  # private_network configures a VirtualBox host-only adapter
  # doesn't work, bug in vbox i think :-(
  #config.vm.network "private_network", type: "dhcp"
  
  config.vm.network "private_network", ip: "192.168.50.4"
  config.vm.define vm_name # Customize the name that shows with vagrant CLI
  #config.vm.hostname vm_name
  config.vm.provider "virtualbox" do |vb|
    vb.name = vm_name # Customize the name that shows in the GUI
    vb.linked_clone = true # Optimize VM creation speed
    vb.memory = "4096"
    vb.cpus = 2
  end

  # Marco

  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y postgresql
  #   sudo -u postgres createdb atc
  #   sudo -u postgres psql <<SQL
  #     CREATE USER vagrant PASSWORD 'vagrant';
  #   SQL
  # SHELL

  config.vm.provision :salt do |salt|
    salt.masterless = true
    salt.minion_config = 'saltstack/etc/minion'
    #salt.bootstrap_options = ''
    salt.run_highstate = true
    salt.colorize = true
    salt.verbose = true
  end

  config.vm.provision :shell, path: "scripts/print_ip.sh", run: 'always'

# FIXME what is this? runs the tests ?  
#  config.vm.provision "shell", path: "scripts/testinfra.sh"

end
