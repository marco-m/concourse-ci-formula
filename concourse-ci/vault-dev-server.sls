{% from "concourse-ci/vault-map.jinja" import vault with context %}

vault_group:
  group.present:
    - name: {{ vault.group }}
    - system: True

vault_user:
  user.present:
    - name: {{ vault.user }}
    - gid: {{ vault.group }}
    - system: True

vault_install_dir:
  file.directory:
    - name: {{ vault.install_dir }}
    - user: {{ vault.user }}
    - group: {{ vault.group }}
    - mode: 755
    - makedirs: True

vault_exe_fetch_and_extract:
  archive.extracted:
    - name: {{ vault.install_dir }}/bin
    - source: {{ vault.exe_url }}
    - source_hash: {{ vault.exe_hash }}
    - enforce_toplevel: False

vault_systemd_unit:
  file.managed:
    - name: /etc/systemd/system/vault.service
    - source: salt://concourse-ci/templates/vault-dev-server.unit.jinja
    - template: jinja
    - mode: 600
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: vault_systemd_unit

vault_running:
  service.running:
    - name: vault
    - enable: True
    - init_delay: 5
    - watch:
      - module: vault_systemd_unit

vault_add_concourse_path:
  cmd.run:
    - env:
      - VAULT_ADDR: {{ vault.server_url }}
    - runas: {{ vault.user }}
    - name: {{ vault.exe }} secrets enable -path=/concourse kv && touch {{ vault.install_dir }}/concourse-path-added
    - creates: {{ vault.install_dir }}/concourse-path-added
    - require:
      - service: vault
