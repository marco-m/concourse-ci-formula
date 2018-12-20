# concourse-in-a-box

All-in-one Concourse installation with S3-compatible storage and Vault secret manager.

This is a one-stop solution that allows to:

1. Learn Concourse pipelines from scratch.
2. Troubleshoot production Concourse pipelines in a simple environment.
3. Write Concourse pipelines that can be reused as-is in your production environment, since it supports S3 and secret `((parameters))`.

Optionally, this repo can be used also as a SaltStack formula (see the full Salt Formulas installation and usage instructions at [SaltStack formulas].

## What's in the box

* VirtualBox VM with Ubuntu 18.04
* [Concourse] 4.2.1 web and worker
* [PostgreSQL] 10, needed by Concourse web
* [Minio] S3-compatible object storage. With this, you can learn writing your Concourse pipelines with S3 without using AWS S3.
* [Vault] 0.10.1 secret and credential manager. With this, you can learn writing your Concourse pipelines following security and operations best practices. See also [Concourse Credential Management] for how Concourse uses Vault.

## Bring up the VM

* Install a recent [VirtualBox] and [Vagrant].
* Run `vagrant up`.

At the end of `vagrant up`, vagrant will print the URL and credentials to use to connect to the Concourse web server and to use `fly`. For example:

```text
     Concourse web server:  http://192.168.50.4:8080
                 Username:  concourse
                 Password:  CHANGEME-8bef502c6d4da90b
                fly login:  fly -t vm login -c http://192.168.50.4:8080 -u concourse -p CHANGEME-8bef502c6d4da90b

      Minio S3 web server:  http://192.168.50.4:9000
S3 endpoint for pipelines:  http://192.168.50.4:9000
            s3_access_key:  minio
            s3_secret_key:  CHANGEME-05ba7d7c95362608

             Vault status:  env VAULT_ADDR=http://192.168.50.4:8200 vault status
           Login to Vault:  env VAULT_ADDR=http://192.168.50.4:8200 vault login CHANGE_ME-b30303da7c0c1299967e075e8ac8aa4b

We just created file 'secrets.txt' in the current directory.
You can use that file to inject into Vault the parameters needed to use S3 storage.

1. Read the README on how to use Vault
2. Login to Vault
3. Read the secrets.txt file to understand what it does
4. Run it (sh secrets.txt)

You can now develop your pipelines securely, since the S3 credentials are stored in Vault.

See as an example tests/pipeline-s3.yml for how to refer to S3.
```

Do **NOT** add to git the `secrets.txt` file, neither to this repository or to any other repository.

## Using Vault

Please refer to the documentation:

* [Concourse parameters]
* [Concourse Credential Management]
* [Vault]

Here we give only the minimal instructions to get started given the particular setup of the VM.

Note that Vault in installed as [Vault dev server], which means:

1. It is unsuitable and insecure for production use.
2. It is using the in-memory backing store, so each time you reload the VM you will loose all your secrets.

All the operations in this section must be performed on the host (the computer hosting the VM).

1. Install the latest `vault` package from [Vault]. The `vault` executable can act either as a client or as a server. Here we will use the client functionality (the server is installed inside the VM).

2. Login to Vault. From the output at the end of `vagrant up`, copy the line that begins with `Login to vault from host`. It will be something similar to `env VAULT_ADDR=http://192.168.50.4:8200 vault login ...`. If you don't have that output handy, you can recreate it with `vagrant ssh -c "/vagrant/scripts/welcome.sh"`.

From now on you can follow the instructions in [Vault your first secret], always using the form `env VAULT_ADDR=http://192.168.50.4:8200 vault ...`

For example, to make the key/value `can_you_read_me/yes_i_can` available to all pipelines in team `main`:

    env VAULT_ADDR=http://192.168.50.4:8200 vault kv put /concourse/main/can_you_read_me value=yes_i_can

This can be referenced in a pipeline as the parameter `((can_you_read_me))`.

NOTE: The indirection with a key with name `value` is specific to the Vault secrets manager. Quoting  [Concourse Credential Management]:

> Vault credentials are actually key-value, so for `((foo))` Concourse will default to the field name `value`.

Other secrets managers such as AWS SSM don't have this indirection, so you would still use the syntax `((can_you_read_me))` in the Concourse pipeline but you would set the key/value in SSM more directly, with something like

    aws ssm put-parameter --name /concourse/main/can_you_read_me --value yes-i-can --type SecureString`.

## Inserting the first secrets into Vault

During VM bringup, a new file has been added in the directory containing the Vagrantfile: `secrets.txt`. This file is ignored in `.gitignore` on purpose.

Although we could have added the contents automatically into Vault, we leave it to the user because in a Concourse production deployment it is the user that has to find a procedure, out-of-band, to add secrets to the secret manager.

By doing this procedure by hand also with Concourse-in-a-box, you will better understand the flow and hopefully understand that there is no "magic" involved.

These instructions are also printed at the end of `vagrant up`:

```text
We just created file 'secrets.txt' in the current directory.
You can use that file to inject into Vault the parameters needed to use S3 storage.

1. Read the README on how to use Vault
2. Login to Vault
3. Read the secrets.txt file to understand what it does
4. Run it (sh secrets.txt)

You can now use your pipelines safely, since the S3 credentials are stored into Vault.

See as an example tests/pipeline-s3.yml for how to refer to S3.
```

NOTE In case you shut down the VM after the first `vagrant up`, you need to issue this command,
which sets the root path for the Concourse secrets:

    vault secrets enable -path=/concourse kv

## Changing credentials or adding S3 buckets

Edit accordingly the files under `saltstack/pillar` and re-apply the salt state by running from the host:

    vagrant ssh -c "sudo salt-call state.apply"

## Updating to a new version of this project

It is normally safe to simply follow these steps:

1. Pull changes

       git pull
       vagrant ssh -c "sudo salt-call state.apply"

2. Re-login into vault and re-add your secrets.

If this fails for some reasons, you can always destroy the VM and re-provision from scratch. In this case you will lose the build history of the pipelines, all configured pipelines (you just have to `fly set-pipeline` again), the build artifacts stored in Minio S3 and the Vault secrets. Loosing all this is not a big deal, you can recreate everything, which is the whole point of the Concourse architecture.

    git pull
    vagrant destroy --force
    vagrant up

## Q&A

**Q**: what are the credentials ?  
**A**: Look into generated file `secrets.txt`. If the file doesn't exist or has wrong credentials, run: `vagrant ssh -c /vagrant/scripts/welcome.sh`, it will both print the information and re-create the `secrets.txt` file.

## Security considerations and production use

The installation uses hard-coded credentials. This is fine as long as you don't change the network configuration (the VM is accessible only from the computer hosting it). If you want to deploy this VM, you MUST change the credentials (see `pillar/concourse.sls`, `pillar/minio.sls`, `pillar/vault.sls`).

Do NOT embed any secret in a Concourse configuration file or build script. Instead, use [Concourse parameters] and the provided Vault. See the tests for an example.

Note also that this VM, with its default values, is for test-driving Concourse, NOT for production use. If you want to do production use, then you need to

* customize it
* add TLS encryption
* in any case: understand how Concourse works.
* Customize the Minio installation.
* Rewrite the Vault installation, which is a [Vault dev server] and completely unfit and insecure for production use.

Unless you know SaltStack well, it is better if you use the official Concourse BOSH distribution.

## Running the tests

The tests, written with [tox], [py.test] and [testinfra], will verify that:

* Concourse web and worker are correctly installed and running.
* Concourse can download a Docker image (a Concourse image_resource).
* Fly can execute a simple task and upload files (this validates the `--external-address` parameter)
* Fly can set and trigger a pipeline.
* The Minio S3 object storage is correctly installed, is running and can be used with Concourse.
* The Vault secret manager is correctly installed, is running and can be used with Concourse.

Setup:

* Download the `fly` binary from the web interface (or fly sync your old binary)
* `pip install tox`

Run:

    tox

## Using the SaltStack formula

### Configuration

As any SaltStack formula, all the configurable settings are in the following files:

States:

* `saltstack/salt/top.sls`

Pillars:

* `pillar.example`
* `saltstack/pillar/concourse.sls`
* `saltstack/pillar/minio.sls`

### Available states

You can either build an all-in-one VM containing everything (this is the default) or create multiple VMs, each one containing the components you want (this requires knowledge of SaltStack).

* `concourse-ci.install` Install the concourse binary.
* `concourse-ci.worker_keys` Install auto-generated keys for concourse worker. Can be overridden to use AWS SSM.
* `concourse-ci.web_keys` Install auto-generated keys for concourse web. Can be overridden to use AWS SSM.
* `concourse-ci.web` Install and run `concourse web` as a systemd service.
* `concourse-ci.worker` Install and run `concourse worker` as a systemd service.
* `concourse-ci.postgres` Install the PostgreSQL ready to be used by concourse web.
* `concourse-ci.minio` Install the Minio S3-compatible object storage server ready to be used by concourse web.
* `vault-dev-server.sls` Install the [Vault dev server] secret manager ready to be used by concourse web. Warning: not configured for production use.

### How to develop the salt formula

From the host, you can trigger the salt states with:

    vagrant up --provision

You can do the same while logged in the VM (this is faster):

    vagrant ssh
    sudo salt-call state.apply

See the section above about how to run the tests.

## TODO

- the tests modify the global state: they leave around pipelines and secrets.
- how do i change the hostname of the VM? It is set to `vagrant`
- remove workaround in concourse-ci/install.sls after salt 2018.3.0

## Credits

Based on https://github.com/mbools/concourse-ci-formula and https://github.com/JustinCarmony/vagrant-salt-example and heavily modified.

## References

* [VirtualBox]
* [Vagrant]
* [Concourse]
* [Concourse parameters]
* [Concourse Credential Management]
* [SaltStack formulas]
* [PostgreSQL]
* [Minio]
* [Vault]
* [Vault dev server]
* [Vault your first secret]
* [tox]
* [py.test]
* [testinfra]

[VirtualBox]: https://www.virtualbox.org
[Vagrant]: https://www.vagrantup.com

[Concourse]: http://concourse-ci.org
[Concourse parameters]: https://concourse-ci.org/creds.html#what-can-be-parameterized
[Concourse Credential Management]: https://concourse-ci.org/creds.html

[SaltStack formulas]: http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html

[PostgreSQL]: https://www.postgresql.org/
[Minio]: https://www.minio.io/
[Vault]: https://www.vaultproject.io/
[Vault dev server]: https://www.vaultproject.io/intro/getting-started/dev-server.html
[Vault your first secret]: https://www.vaultproject.io/intro/getting-started/first-secret.html

[tox]: https://tox.readthedocs.io/
[py.test]: https://www.pytest.org/
[testinfra]: https://testinfra.readthedocs.io/
