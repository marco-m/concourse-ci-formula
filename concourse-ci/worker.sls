{% from "concourse-ci/map.jinja" import concourse with context %}

include:
  - concourse-ci.install
  - concourse-ci.keys

{{ concourse.worker.work_dir }}:
  file.directory:
    - user: {{ concourse.user }}
    - group: {{ concourse.group }}
    - mode: 755
    - makedirs: True

concourse-worker_systemd_unit:
  file.managed:
    - name: /etc/systemd/system/concourse-worker.service
    - source: salt://concourse-ci/templates/worker.unit.jinja
    - template: jinja
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: concourse-worker_systemd_unit

concourse-worker_running:
  service.running:
    - name: concourse-worker
    - watch:
      - module: concourse-worker_systemd_unit
