{% from "concourse-ci/map.jinja" import concourse with context %}

{%- if concourse.web.pki is defined %}

{{ concourse.pki_dir }}/tsa_host_key:
  file.managed:
    {%- if concourse.web.pki.host_key_url is defined %}
    - source: {{ concourse.web.pki.host_key_url }}
    {%- else %}
    - contents_pillar: 'concourse.web.pki.host_key'
    {%- endif %}
    - user: {{ concourse.user }}
    - group: {{ concourse.group }}
    - mode: 600

{{ concourse.pki_dir }}/session_signing_key:
  file.managed:
    {%- if concourse.web.pki.session_key_url is defined %}
    - source: {{ concourse.web.pki.session_key_url }}
    {%- else %}
    - contents_pillar: 'concourse.web.pki.session_key'
    {%- endif %}
    - user: {{ concourse.user }}
    - group: {{ concourse.group }}
    - mode: 600

{{ concourse.pki_dir }}/authorized_worker_keys:
  file.managed:
    - user: {{ concourse.user }}
    - group: {{ concourse.group }}
    - mode: 600

populate {{ concourse.pki_dir }}/authorized_worker_keys:
  file.append:
    - name: {{ concourse.pki_dir }}/authorized_worker_keys
    {%- if concourse.web.pki.authorized_worker_cert_urls is defined %}
    - sources:
      {%- for worker_cert_url in concourse.web.pki.authorized_worker_cert_urls %}
      - {{ worker_cert_url }}
      {%- endfor %}
    {%- else %}
    - text: |
      {%- for worker_cert in concourse.web.pki.authorized_worker_certs %}
      {{ worker_cert }}
      {%- endfor %}
    {%- endif %}
{%- endif %}

{%- if concourse.worker.pki is defined %}
{{ concourse.pki_dir }}/worker_key:
  file.managed:
    {%- if concourse.worker.pki.worker_key_url is defined %}
    - source: {{ concourse.worker.pki.worker_key_url }}
    {%- else %}
    - contents_pillar: 'concourse.web.pki.worker_key'
    {%- endif %}
    - user: {{ concourse.user }}
    - group: {{ concourse.group }}
    - mode: 600

{{ concourse.pki_dir }}/tsa_host_key.pub:
  file.managed:
    {%- if concourse.worker.pki.tsa_host_cert_url is defined %}
    - source: {{ concourse.worker.pki.tsa_host_cert_url }}
    {%- else %}
    - contents_pillar: 'concourse.web.pki.tsa_host_cert'
    {%- endif %}
    - user: {{ concourse.user }}
    - group: {{ concourse.group }}
    - mode: 600

{%- endif %}
