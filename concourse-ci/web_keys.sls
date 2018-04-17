{% from "concourse-ci/map.jinja" import concourse with context %}

generate_tsa_host_key:
  cmd.run:
    - name: |
        rm -f tsa_host_key
        ssh-keygen -t rsa -f tsa_host_key -N ''
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - creates:
      - {{ concourse.pki_dir }}/tsa_host_key
      - {{ concourse.pki_dir }}/tsa_host_key.pub

{% if concourse.ssm_tsa_private_key and concourse.ssm_worker_public_key %}
replace_private_tsa_key:
  cmd.run:
    - name: "aws ssm get-parameter --region eu-west-1 --name '{{ concourse.ssm_tsa_private_key }}' --with-decrypt --query 'Parameter.Value' --output text > tsa_host_key"
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - onchanges-in:
      - concourse-web_running

replace_public_worker_key:
  cmd.run:
    - name: "aws ssm get-parameter --region eu-west-1 --name '{{ concourse.ssm_worker_public_key }}' --with-decrypt --query 'Parameter.Value' --output text > worker_key.pub"
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - onchanges-in:
      - concourse-web_running
    - require-in:
      - ensure-authorized-worker-keys

{% if not concourse.ssm_worker_private_key %} # I am a standalone web and these keys are spurious
cleanup_spurious_worker_private_key:
  file.absent:
    - name: {{ concourse.pki_dir }}/worker_key

cleanup_spurious_tsa_key:
  file.absent:
    - name: {{ concourse.pki_dir }}/tsa_host_key.pub
{% endif %}
{% endif %}

dummy_worker_public_key:
  cmd.run:
    - name: "touch {{ concourse.pki_dir }}/worker_key.pub"
    - runas: {{ concourse.user }}

ensure_authorized_worker_keys:
  file.symlink:
    - name: {{ concourse.pki_dir }}/authorized_worker_keys
    - user: {{ concourse.user }}
    - target: {{ concourse.pki_dir }}/worker_key.pub
    - require-in:
      - concourse-web_running
