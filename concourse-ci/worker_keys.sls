{% from "concourse-ci/map.jinja" import concourse with context %}

generate_worker_keys:
  cmd.run:
    - name: "ssh-keygen -t rsa -f worker_key -N ''"
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - creates:
      - {{ concourse.pki_dir }}/worker_key
      - {{ concourse.pki_dir }}/worker_key.pub

{% if concourse.ssm_worker_private_key and concourse.ssm_tsa_public_key %}
replace_private_worker_key:
  cmd.run:
    - name: "aws ssm get-parameter --region eu-west-1 --name '{{ concourse.ssm_worker_private_key }}' --with-decrypt --query 'Parameter.Value' --output text > worker_key"
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - onchanges-in:
      - concourse-worker_running

place_public_tsa_key:
  cmd.run:
    - name: "aws ssm get-parameter --region eu-west-1 --name '{{ concourse.ssm_tsa_public_key }}' --with-decrypt --query 'Parameter.Value' --output text > tsa_host_key.pub"
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - onchanges-in:
      - concourse-worker_running

{% if not concourse.ssm_tsa_private_key %} # I am a standalone worker and the worker public key is spurious
cleanup_spurious_worker_public_key:
  file.absent:
    - name: {{ concourse.pki_dir }}/worker_key.pub
{% endif %}
{% endif %}
