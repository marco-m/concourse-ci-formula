{% from "concourse-ci/minio-map.jinja" import minio with context %}

# Install a minimal https://www.minio.io S3-compatible object storage server
# for usage with Concourse all-in-one.

minio_group:
  group.present:
    - name: {{ minio.group }}
    - system: True

minio_user:
  user.present:
    - name: {{ minio.user }}
    - gid: {{ minio.group }}
    - system: True

minio_install_dir:
  file.directory:
    - name: {{ minio.install_dir }}
    - user: {{ minio.user }}
    - group: {{ minio.group }}
    - mode: 755
    - makedirs: True

minio_conf_dir:
  file.directory:
    - name: {{ minio.conf_dir }}
    - user: {{ minio.user }}
    - group: {{ minio.group }}
    - mode: 700
    - makedirs: True

minio_storage_dir:
  file.directory:
    - name: {{ minio.storage_dir }}
    - user: {{ minio.user }}
    - group: {{ minio.group }}
    - mode: 755
    - makedirs: True

{% for bucket in minio.buckets %}
minio_bucket_{{ bucket }}:
  file.directory:
    - name: {{ minio.storage_dir }}/{{ bucket }}
    - user: {{ minio.user }}
    - group: {{ minio.group }}
    - mode: 755
{% endfor %}

minio_server_fetch:
  file.managed:
    - name: {{ minio.server_exe }}
    - source:
      - {{ minio.server_url }}
    - skip_verify: True  
    - mode: 755

minio_systemd_unit:
  file.managed:
    - name: /etc/systemd/system/minio.service
    - source: salt://concourse-ci/templates/minio.unit.jinja
    - template: jinja
    - mode: 600
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: minio_systemd_unit

minio_running:
  service.running:
    - name: minio
    - enable: True
    - watch:
      - module: minio_systemd_unit

minio_client_fetch:
  file.managed:
    - name: {{ minio.client_exe }}
    - source:
      - {{ minio.client_url }}
    - skip_verify: True  
    - mode: 755

# Adding credentials to the minio client triggers a runtime check against the configured server,
# so this step needs to be done after the server is running.
minio_client_configure:
  cmd.run:
    - runas: {{ minio.user }}
    - name: {{ minio.client_exe }} config host add minio {{ minio.endpoint }} {{ minio.access_key }} {{ minio.secret_key }}

{% if salt['user.info']('vagrant') %}
minio_client_configure_vagrant:
  cmd.run:
    - runas: vagrant
    - name: {{ minio.client_exe }} config host add minio {{ minio.endpoint }} {{ minio.access_key }} {{ minio.secret_key }}
{% endif %}
