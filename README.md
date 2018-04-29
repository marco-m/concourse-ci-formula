# concourse-ci

All-in-one-VM Concourse installation and SaltStack formula to install Concourse.

## What's in the box

* VM with Ubuntu 18.04
* [concourse-ci] web and worker 3.12
* [Postgres] DB needed by Concourse web
* [Minio] S3-compatible object storage, so that you can learn writing your pipelines with S3 without using AWS S3.

## What can I do with this

You can use this repo for two purposes:

1. To bring up a fully functioning Concourse installation with Vagrant and VirtualBox (follow next section "Using Concourse").
2. As a SaltStack formula (see the full Salt Formulas installation and usage instructions at [SaltStack formulas]

## Using Concourse

* Install a recent [VirtualBox] and [Vagrant].
* Run `vagrant up`.

At the end of `vagrant up`, vagrant will print the URL and credentials to use to connect to the Concourse web server and to use `fly`. For example:

```text
      Concourse web server:  http://localhost:8080
                 fly login:  fly -t vm login -c http://localhost:8080 -u concourse -p CHANGEME
                  Username:  concourse
                  Password:  CHANGEME

       Minio S3 web server:  http://localhost:9000
 S3 endpoint for pipelines:  http://10.0.2.15:9000
             s3_access_key:  minio
             s3_secret_key:  CHANGEME

    VM internal IP address:  10.0.2.15
 We just created file 'credentials.yml' in the current directory.
 You can use that file to set parametrized pipelines as follows:

     fly set-pipeline ... --load-vars-from=credentials.yml

 See as examples the pipelines in the 'tests' directory.
```

Do **NOT** add to git the `credentials.yml` file, neither to this repository or to any other repository.

You can use the Minio server to replace AWS S3, so that you can test-drive a full pipeline with artifacts passed from one job to another.

## Changing credentials or adding S3 buckets

Edit accordingly the files under `saltstack/pillar` and re-apply the salt state by running from the host:

    vagrant ssh -c "sudo salt-call state.apply"

## Updating to a new version of this project

It is normally safe to simply do

    git pull
    vagrant ssh -c "sudo salt-call state.apply"

If this fails for some reasons, you can always destroy the VM and re-provision from scratch. In this case you will lose the build history of the pipelines, all configured pipelines (you just have to `fly set-pipeline` again) and the build artifacts stored in Minio S3. Loosing all this is not a big deal, you can recreate everything, which is the whole point of the Concourse architecture.

    git pull
    vagrant destroy --force
    vagrant up

## Q&A

**Q**: what are the credentials ?  
**A**: Look into generated file `credentials.yml`. If the file doesn't exist or has wrong credentials, run: `vagrant ssh -c /vagrant/scripts/welcome.sh`, it will both print the information and re-create the `credentials.yml` file.

**Q**: Why the `Minio S3 web server` is listening on `http://localhost:9000` while the `S3 endpoint for pipelines` is something like `http://10.0.2.15:9000` ?  
**A**: Because the `Minio S3 webserver` is meant to be reachable by the user from the host running the VM, so it is using VirtualBox port forwarding. On the other end, the `S3 endpoint for pipelines` is used by the Concourse pipeline. Since the pipeline is running inside a container with a different network namespace, it cannot accept `localhost` addresses. As such, we pass the non-routable address that VirtualBox assigns by DHCP to the first network interface of the VM guest. Normally you don't have to worry for any of this, just pass `credentials.yml` to your parametric pipeline.

## Security considerations and production use

The installation uses hard-coded credentials. This is fine as long as you don't change the network configuration (the VM is accessible only from the computer hosting it). If you want to deploy this VM, you MUST change the credentials (see `pillar/concourse.sls` and `pillar/minio.sls`).

Do NOT embed any secret in a Concourse configuration file or build script. Instead, use [Concourse parameters]. See the tests for an example.

Note also that this VM, with its default values, is for test-driving Concourse, NOT for production use. If you want to do production use, then you need to

* customize it
* add TLS encryption
* in any case: understand how Concourse works.

Unless you know SaltStack well, it is better if you use the official Concourse BOSH distribution. Same reasoning for the bundled Minio installation.

## Running the tests

The tests, written with the very good py.test and testinfra, will verify that:

* Concourse web and worker are correctly installed and running.
* Concourse can download a Docker image (a Concourse image_resource).
* Fly can execute a simple task and upload files (this validates the `--external-address` parameter)
* Fly can set and trigger a pipeline.
* The Minio S3 object storage is correctly installed, is running and can be used with Concourse.

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
* `concourse-ci.postgres` Install the Postgres ready to be used by concourse web.
* `concourse-ci.minio` Install the Minio S3-compatible object storage server ready to be used by concourse web.

### How to develop the salt formula

From the host, you can trigger the salt states with:

    vagrant up --provision

You can do the same while logged in the VM (this is faster):

    vagrant ssh
    sudo salt-call state.apply

See the section above about how to run the tests.

## TODO

- how do i change the hostname of the VM? It is set to `vagrant`
- remove workaround in concourse-ci/install.sls after salt 2018.3.0

## Credits

Based on https://github.com/mbools/concourse-ci-formula and https://github.com/JustinCarmony/vagrant-salt-example and heavily modified.

## Tips & Tricks

### Concourse Documentation Readability Improvement

One can improve the readability of the concourse documentation by modifying their CSS style to get a larger column. Here is how:

- Install the Stylish extension if not already present.
- Click on its icon and then on the 3-dots icon in the top right corner of the pop-up.
- Pick "Create New Style"
- In the new tab, click the "Import" button from the "Mozilla Format" section and paste-in this:
```css
@-moz-document url-prefix("https://concourse-ci.org/") {
.page {
    flex: 2;
}

.examples {
    flex: 1;
}
}
```

* Close the pop-up by clicking the "Overwrite style" button.
* Enter a name and then click the "Save" button.
* Reload the concourse documentation page and enjoy.

## References

* [VirtualBox]
* [Vagrant]
* [concourse-ci]
* [Concourse parameters]
* [Concourse Credential Management]
* [SaltStack formulas]
* [Postgres]
* [Minio]

[VirtualBox]: https://www.virtualbox.org
[Vagrant]: https://www.vagrantup.com

[concourse-ci]: http://concourse-ci.org
[Concourse parameters]: https://concourse-ci.org/creds.html#what-can-be-parameterized
[Concourse Credential Management]: https://concourse-ci.org/creds.html

[SaltStack formulas]: http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html

[Postgres]: https://www.postgresql.org/
[Minio]: https://www.minio.io/
