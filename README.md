# concourse-ci

SaltStack formula for the [concourse-ci] continuous integration server.

Based on https://github.com/mbools/concourse-ci-formula and https://github.com/JustinCarmony/vagrant-salt-example and heavily modified.

## Status

* in development
* works fine with VirtualBox
* some hardcoded assumptions on VirtualBox that need to change

## Usage

You can use this repo either as a SaltStack formula or simply to bring up a fully functioning Concourse installation with Vagrant and VirtualBox.

See the full Salt Formulas installation and usage instructions at http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html

### Configuration

As any SaltStack formula, all the configurable settings are in file `pillar.example`. You need to copy this file to your pillar directory and rename it to `concourse-ci.sls` in order for it to be loaded.

## Available states

### `concourse-ci.keys`

Install auto-generated Concourse keys for web and worker.

### `concourse-ci.web`

Install and run `concourse web` as a service (currently only `systemd`).

### `concourse-ci.worker`

Install and run `concourse worker` as a service (currently only `systemd`).

### `concourse-ci.postgres`

Installs Postgres ready to be used by concourse web.

## Test driving Concourse

At the end of `vagrant up`, vagrant will print the URL to use to connect to the Concourse web and to use `fly`.

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