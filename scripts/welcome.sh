#!/bin/sh
# This script is supposed to run on the VM, NOT on the host!

salt_call()
{
  echo $(sudo salt-call $1 $2 | tail -1 | tr -d ' ')    
}

external_ip="localhost"
internal_ip=$(salt_call network.interface_ip eth0)
user=$(salt_call pillar.get concourse:lookup:web_auth_basic_username)
password=$(salt_call pillar.get concourse:lookup:web_auth_basic_password)

access_key=$(salt_call pillar.get minio:lookup:access_key)
secret_key=$(salt_call pillar.get minio:lookup:secret_key)

echo "."
echo "       Concourse web server:  http://${external_ip}:8080"
echo "                  fly login:  fly -t ci login -c http://${external_ip}:8080"
echo "                   Username:  ${user}"
echo "                   Password:  ${password}"
echo
echo "    Minio S3 object storage:"
echo "                 access_key:  ${access_key}"
echo "                 secret_key:  ${secret_key}"
echo "  S3 endpoint for pipelines:  http://${internal_ip}:9000"
echo "           Minio web server:  http://${external_ip}:9000"
echo "."
