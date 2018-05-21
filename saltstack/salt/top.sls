base:
  'vagrant.vm':
    - concourse-ci.vault-dev-server
    - concourse-ci.minio
    - concourse-ci.postgres
    - concourse-ci.install
    - concourse-ci.worker_keys
    - concourse-ci.web_keys
    - concourse-ci.web
    - concourse-ci.worker
