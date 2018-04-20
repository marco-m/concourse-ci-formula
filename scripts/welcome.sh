#!/bin/sh
# This script is supposed to run on the VM, NOT on the host!

salt_call()
{
  sudo salt-call "$1" "$2" | tail -1 | tr -d ' '
}

external_ip="localhost"
internal_ip=$(salt_call network.interface_ip eth0)

concourse_username=$(salt_call pillar.get concourse:lookup:web_auth_basic_username)
concourse_password=$(salt_call pillar.get concourse:lookup:web_auth_basic_password)

s3_access_key=$(salt_call pillar.get minio:lookup:access_key)
s3_secret_key=$(salt_call pillar.get minio:lookup:secret_key)
s3_endpoint=$(salt_call pillar.get minio:lookup:endpoint)

cat <<EOF

     Concourse web server:  http://${external_ip}:8080
                fly login:  fly -t vm login -c http://${external_ip}:8080 -u ${concourse_username} -p ${concourse_password}
                 Username:  ${concourse_username}
                 Password:  ${concourse_password}

      Minio S3 web server:  http://${external_ip}:9000
S3 endpoint for pipelines:  ${s3_endpoint}
            s3_access_key:  ${s3_access_key}
            s3_secret_key:  ${s3_secret_key}

   VM internal IP address:  ${internal_ip}

To get started, copy the following lines to file 'credentials.yml'; you can then set parametrized pipelines with:
  fly set-pipeline ... --load-vars-from=credentials.yml


minio-endpoint: ${s3_endpoint}
s3-access-key-id: ${s3_access_key}
s3-secret-access-key: ${s3_secret_key}

EOF
echo "."