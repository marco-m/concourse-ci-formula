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

prefix = Pathname.getwd.parent.basename.to_s
vm_name = "#{prefix}_concourse-formula"
Vagrant.configure("2") do |config|

  # Why not 16.04 LTS ? Because we want btrfs for performance and we need a
  # recent kernel to reduce the many bugs seen with Concourse and btrfs.
  config.vm.box = "bento/ubuntu-17.10"

  # INT-1419
  # NOTE concourse web has a mandatory option "--external-url" that:
  # 1. Cannot be loopback (reason of "external" in the name).
  # 2. Must be reachable from the host, so on VirtualBox it cannot be the address
  #    of the first guest interface (eth0) plus VirtualBox port forwarding of 8080
  # This means that unfortunately we need a separate interface (which by itself is not
  # a problem; it becomes a problem because we want to use the same SaltStack configuration
  # both for VirtualBox and for AMI, and for the AMI we want only one interface).
  # This is a known problem in Concourse and there is a ticket for it
  # https://github.com/concourse/concourse/issues/2069
  # which should be addressed soon (March 2018).

  # Ideally we would like to use VirtualBox DHCP to assign an address:
  #config.vm.network "private_network", type: "dhcp"
  # but it doesn't work for some reasons I don't understand, so we are stuck with
  # an hard-coded IP address
  config.vm.network "private_network", ip: "192.168.50.4"
  config.vm.define vm_name # Customize the name that shows with vagrant CLI
  #config.vm.hostname vm_name
  config.vm.provider "virtualbox" do |vb|
    vb.name = vm_name # Customize the name that shows in the VirtualBox GUI
    vb.linked_clone = true # Optimize VM creation speed
    vb.memory = "4096"
    vb.cpus = 2
  end

  config.vm.provision :salt do |salt|
    salt.masterless = true
    salt.minion_config = 'saltstack/etc/minion'
    salt.run_highstate = true
    salt.colorize = true
    salt.verbose = true
  end

  config.vm.provision :shell, path: "scripts/welcome.sh", run: 'always'
end
