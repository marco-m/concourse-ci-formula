#!/bin/sh
# This script is supposed to run on the VM, NOT on the host!

ip=$(salt-call network.interface_ip eth1 | tail -1 | tr -d '[:space:]')
user_key="concourse:lookup:web_auth_basic_username"
password_key="concourse:lookup:web_auth_basic_password"
user=$(sudo salt-call pillar.get ${user_key} | tail -1 | tr -d '[:space:]')
password=$(sudo salt-call pillar.get ${password_key} | tail -1 | tr -d '[:space:]')

echo "Concourse web server:    http://${ip}:8080"
echo "           fly login:    fly -t ci login -c http://${ip}:8080"
echo "         Credentials:    ${user} ${password}"
