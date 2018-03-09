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
    - name: {{ concourse.postgres.user }}
    - password: {{ concourse.postgres.password }}

concourse_create_postgres_database:
  postgres_database.present:
    - name: 'atc'
    - owner: {{ concourse.postgres.user }}
