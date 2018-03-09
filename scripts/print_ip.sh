#!/bin/sh

ip=$(sudo salt-call network.ip_addrs | egrep -v 'local|\- 10\.' | awk '{print $2}')

echo "The Concourse server is available at http://${ip}:8080"
echo "fly -t ci login -c http://${ip}:8080"