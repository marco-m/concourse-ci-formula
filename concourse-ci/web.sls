{% from "concourse-ci/map.jinja" import concourse with context %}

include:
  - concourse-ci.install
  - concourse-ci.keys

concourse-web_systemd_unit:
  file.managed:
    - name: /etc/systemd/system/concourse-web.service
    - source: salt://concourse-ci/templates/web.unit.jinja
    - template: jinja
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: concourse-web_systemd_unit

concourse-web_running:
  service.running:
    - name: concourse-web
    - watch:
      - module: concourse-web_systemd_unit
