{% from "concourse-ci/map.jinja" import concourse with context %}

generate_session_signing_key:
  cmd.run:
    - name: "ssh-keygen -t rsa -f session_signing_key -N ''"
    - runas: {{ concourse.user }}
    - cwd: {{ concourse.pki_dir }}
    - creates:
      - {{ concourse.pki_dir }}/session_signing_key
      - {{ concourse.pki_dir }}/session_signing_key.pub

concourse-web_systemd_unit:
  file.managed:
    - name: /etc/systemd/system/concourse-web.service
    - source: salt://concourse-ci/templates/web.unit.jinja
    - template: jinja
    - mode: 600
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: concourse-web_systemd_unit

concourse-web_running:
  service.running:
    - name: concourse-web
    - enable: True
    - watch:
      - module: concourse-web_systemd_unit
