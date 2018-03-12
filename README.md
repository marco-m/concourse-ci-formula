# concourse-ci

Single VM Concourse installation and SaltStack formula to install Concourse.

## Status

* in development
* works fine with VirtualBox
* some hardcoded assumptions on VirtualBox that need to change

## Usage

You can use this repo for two purposes:

1. To bring up a fully functioning Concourse installation with Vagrant and VirtualBox (follow section "Test driving Concourse").
2. As a SaltStack formula (see the full Salt Formulas installation and usage instructions at http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html).

## Test driving Concourse

* Install a recent [VirtualBox] and [Vagrant].
* Run `vagrant up`.

At the end of `vagrant up`, vagrant will print the URL and credentials to use to connect to the Concourse web and to use `fly`. For example:

    ...
    concourse-formula: The Concourse server is available at http://192.168.50.4:8080
    concourse-formula: fly -t ci login -c http://192.168.50.4:8080
    concourse-formula: Credentials: XXX YYY

## Security considerations and production use

The installation uses hard-coded credentials. This is fine as long as you don't change the network configuration (the VM is accessible only from the computer hosting it). If you want to deploy this VM, you MUST change the credentials (see `pillar/concourse.sls`).

Note also that this VM, with its default values, is for test-driving Concourse, NOT for production use. If you want to do production use, then you need to customize it and in any case understand how Concourse works. Unless you know SaltStack well, it is better if you use the official Concourse BOSH distribution.

## Running the tests

The tests will verify that:

* Concourse web and worker are correctly installed and running
* Concourse can download a Docker image
* Fly can execute a simple task and upload files (this validates the `--external-address` parameter)

Run:

    download a fly binary from the web interface (or fly sync your old binary)
    pip install -u requirements.txt
    cd tests
    vagrant ssh-config > ssh-config.tmp
    py.test --hosts=concourse-formula --ssh-config=ssh-config.tmp

## SaltStack formula

### Configuration

As any SaltStack formula, all the configurable settings are in file `pillar.example`. You need to copy this file to your pillar directory and rename it to `concourse-ci.sls` in order for it to be loaded.

### Available states

#### `concourse-ci.keys`

Install auto-generated Concourse keys for web and worker.

#### `concourse-ci.web`

Install and run `concourse web` as a service (currently only `systemd`).

#### `concourse-ci.worker`

Install and run `concourse worker` as a service (currently only `systemd`).

#### `concourse-ci.postgres`

Installs Postgres ready to be used by concourse web.

## How to develop

From the host, you can trigger the salt states with:

    vagrant up --provision

You can do the same while logged in the VM (this is faster):

    sudo salt-call state.apply

## TODO

- update tox.ini to run the tests in a simpler way
- now the worker register itself using its hostname, in this case `vagrant`. This might need to change to its ip address, i saw somewhere that the ATC is confused if a worker is respawned, gets a new ip address and registers with an already known hostname...
- it seems that also concourse web runs as root (in addition to the worker), but the tsa should NOT run as root, fix it in the systemd unit file
- how do i change the hostname of the VM? It is set to `vagrant`

[concourse-ci]: http://concourse-ci.org/

## Credits

Based on https://github.com/mbools/concourse-ci-formula and https://github.com/JustinCarmony/vagrant-salt-example and heavily modified.

[VirtualBox]: https://www.virtualbox.org/
[Vagrant]: https://www.vagrantup.com/
