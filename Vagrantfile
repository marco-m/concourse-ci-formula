# Enforce minimum version both for Vagrant and VirtualBox.
Vagrant.require_version ">= 2.2.3"
MIN_VIRTUALBOX_VERSION = Gem::Version.new('5.2.26')
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

vm_name = "concourse-ansible"
Vagrant.configure("2") do |config|

  config.vm.box = "archlinux/archlinux"

  # NOTE 'concourse web' went back and forth with option `--external-url` being sometimes
  # mandatory and sometimes optional. It became mandatory again with Concourse 4.x.
  # It has the following characteristics:
  # 1. Cannot be loopback (reason of "external" in the name).
  # 2. Must be reachable from the host, so on VirtualBox it cannot be the address
  #    of the first guest interface (eth0) plus VirtualBox port forwarding of 8080
  # This means that unfortunately we need a separate interface (which by itself is not
  # a problem; it becomes a problem because we want to use the same SaltStack configuration
  # both for VirtualBox and for AMI, and for the AMI we want only one interface).

  # Ideally we would like to use VirtualBox DHCP to assign an address:
  #config.vm.network "private_network", type: "dhcp"
  # but it doesn't work for some reasons I don't understand, so we are stuck with
  # an hard-coded IP address
  config.vm.network "private_network", ip: "192.168.50.4"

  # Customize the name that shows with vagrant CLI
  config.vm.define vm_name
  config.vm.hostname = vm_name
  config.vm.provider "virtualbox" do |vb|
    vb.name = vm_name # Customize the name that shows in the VirtualBox GUI
    vb.linked_clone = true # Optimize VM creation speed
    vb.memory = "4096"
    vb.cpus = 2
    vb.default_nic_type = "virtio"
  end

  # The DNS mess with ArchLinux and VirtualBox:
  #
  # By default, /etc/resolv.conf points to 10.0.2.3 and
  # 1. `drill www.x.org` works fine. It uses the right resolver at 10.0.2.3.
  # 2. `ping www.x.org` times out. It means it uses something else, probably 
  #    127.0.0.53, which for some reason is broken.
  #
  # If I run "ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf",
  # it makes /etc/resolv.conf point to 127.0.0.53. Drill always goes to 10.0.2.3
  # and works, ping fails as before. If I ask explicitly drill to use 127.0.0.53,
  # I get: "Error: error sending query: Could not send or receive, because of network error"
  #
  # Finally found a workaround! /etc/nsswitch.conf specifies `resolver`
  # before `dns`:
  #     hosts: files mymachines myhostname resolve [!UNAVAIL=return] dns
  # If we swap the order, finally also utilities like ping work!
  config.vm.provision "shell" do |s|
    s.inline = "sed --in-place 's/hosts:.*/hosts: files mymachines myhostname dns resolve/' /etc/nsswitch.conf"
  end

  config.vm.provision "shell" do |s|
    # Upgrading the system is needed before ever attempting to install Python;
    # I saw bizarre failure modes without.
    s.inline = "pacman -Syu --noconfirm"
  end

  config.vm.provision "shell" do |s|
    # Ansible needs Python on the target.
    s.inline = "pacman -S --noconfirm --needed python3"
  end



  # config.vm.provision "ansible" do |ansible|
  #   ansible.compatibility_mode = "2.0"
  #   ansible.playbook = "playbook.yml"
  # end

  #config.vm.provision :shell, path: "scripts/welcome.sh", run: 'always'
end
