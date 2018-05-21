# Enforce minimum version both for Vagrant and VirtualBox.
Vagrant.require_version ">= 2.1.1"
MIN_VIRTUALBOX_VERSION = Gem::Version.new('5.2.12')
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

prefix = Pathname.getwd.parent.basename.to_s
vm_name = "#{prefix}_concourse-formula"
Vagrant.configure("2") do |config|

  config.vm.box = "bento/ubuntu-18.04"

  # Concourse web
  config.vm.network "forwarded_port", host_ip: "127.0.0.1", host: 8080, guest: 8080
  # Minio
  config.vm.network "forwarded_port", host_ip: "127.0.0.1", host: 9000, guest: 9000
  # Vault
  config.vm.network "forwarded_port", host_ip: "127.0.0.1", host: 8200, guest: 8200

  config.vm.define vm_name # Customize the name that shows with vagrant CLI
  #config.vm.hostname vm_name
  config.vm.provider "virtualbox" do |vb|
    vb.name = vm_name # Customize the name that shows in the VirtualBox GUI
    vb.linked_clone = true # Optimize VM creation speed
    vb.memory = "4096"
    vb.cpus = 2
  end

  #config.vm.provision "shell", inline: "DEBIAN_FRONTEND=noninteractive apt-get update"
  #config.vm.provision "shell", inline: "DEBIAN_FRONTEND=noninteractive apt-get --quiet --yes upgrade"

  config.vm.provision :salt do |salt|
    salt.masterless = true
    salt.minion_config = 'saltstack/etc/minion'
    salt.run_highstate = true
    salt.colorize = true
    salt.verbose = true
  end

  config.vm.provision :shell, path: "scripts/welcome.sh", run: 'always'
end
