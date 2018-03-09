{% from "concourse-ci/map.jinja" import concourse with context %}

ssh-client:
  pkg.installed:
    - name: 'openssh-client'

generate-tsa-host-key:
  cmd.run:
    - name: "ssh-keygen -t rsa -f tsa_host_key -N ''"
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - creates:
      - {{ concourse.pki_dir }}/tsa_host_key
      - {{ concourse.pki_dir }}/tsa_host_key.pub

generate-worker-key:
  cmd.run:
    - name: "ssh-keygen -t rsa -f worker_key -N ''"
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - creates:
      - {{ concourse.pki_dir }}/worker_key
      - {{ concourse.pki_dir }}/worker_key.pub

generate-authorized-worker-keys:
  cmd.run:
    - name: "cp worker_key.pub authorized_worker_keys"
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - creates:
      - {{ concourse.pki_dir }}/authorized_worker_keys

generate_session_signing_key:
  cmd.run:
    - name: "ssh-keygen -t rsa -f session_signing_key -N ''"
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - creates:
      - {{ concourse.pki_dir }}/session_signing_key
      - {{ concourse.pki_dir }}/session_signing_key.pub
