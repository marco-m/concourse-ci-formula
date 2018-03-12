#!/bin/sh
# This script is supposed to run on the VM, NOT on the host!

ip=$(sudo salt-call network.ip_addrs | egrep -v 'local|\- 10\.' | awk '{print $2}')
user=$(sudo salt-call pillar.get concourse:lookup:web_auth_basic_username | tail -1)
password=$(sudo salt-call pillar.get concourse:lookup:web_auth_basic_password | tail -1)

echo "The Concourse server is available at http://${ip}:8080"
echo "fly -t ci login -c http://${ip}:8080"
echo "Credentials: ${user} ${password}"
