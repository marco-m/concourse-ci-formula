{% from "concourse-ci/map.jinja" import concourse with context %}

group_{{ concourse.group }}:
  group.present:
    - name: {{ concourse.group }}
    - system: True

user_{{ concourse.user }}:
  user.present:
    - name: {{ concourse.user }}
    - gid: {{ concourse.group }}
    - system: True

{{ concourse.install_dir }}:
  file.directory:
    - user: {{ concourse.user }}
    - group: {{ concourse.group }}
    - mode: 755
    - makedirs: True

{{ concourse.pki_dir }}:
  file.directory:
    - user: {{ concourse.user }}
    - group: {{ concourse.group }}
    - mode: 755
    - makedirs: True

{{ concourse.bin_dir }}:
  file.directory:
    - user: {{ concourse.user }}
    - group: {{ concourse.group }}
    - mode: 755
    - makedirs: True

{{ concourse.bin_dir }}/concourse:
  file.managed:
    - source:
      - {{ concourse.exe_url }}
    - source_hash: {{ concourse.exe_hash }}
    - user: {{ concourse.user }}
    - group: {{ concourse.group }}
    - mode: 755
