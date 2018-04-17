{% from "concourse-ci/map.jinja" import concourse with context %}

postgres:
  pkg.installed:
    - name: 'postgresql'

# These states below are the equivalent of:
#
#   sudo -u postgres createdb atc
#   sudo -u postgres psql <<SQL
#     CREATE USER vagrant PASSWORD 'vagrant';
#   SQL

concourse_create_postgres_user:
  postgres_user.present:
    - user: 'postgres'
    - name: {{ concourse.postgres_user }}
    - password: {{ concourse.postgres_password }}

concourse_create_postgres_database:
  postgres_database.present:
    - name: 'atc'
    - owner: {{ concourse.postgres_user }}


{% if concourse.postgres_hba %}

{% if salt['cmd.run']('pg_conftool get -s listen_addresses') != '*' %}
listen_on_all_addresses:
  cmd.run:
    - name: pg_conftool set listen_addresses '*'
    - watch_in:
      - service_running
{% endif %}

configure_access_control_list:
  file.append:
    - name: /etc/postgresql/{{ concourse.postgres_version }}/main/pg_hba.conf
{% for record in concourse.postgres_hba %}
    - text: {{ record.connection }} {{ record.database }} {{ record.user }} {{ record.address }} {{ record.method }}
{% endfor %}

service_running:
  service.running:
    - name: postgresql
    - enable: True
    - watch:
      - file: /etc/postgresql/{{ concourse.postgres_version }}/main/pg_hba.conf

{% endif %}
