base:
  'vagrant.vm':
    - concourse-ci.postgres
    - concourse-ci.install
    - concourse-ci.worker_keys
    - concourse-ci.web_keys
    - concourse-ci.web
    - concourse-ci.worker
    - concourse-ci.minio
