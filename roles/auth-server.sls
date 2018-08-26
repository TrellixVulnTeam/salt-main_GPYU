{% set data = pillar['auth-server'] %}
{% set db = data['db'] %}

auth-server-packages:
  pkg.installed:
    - pkgs:
      - slapd

auth-server-pip:
  pip.installed:
    - name: PyMySQL
    - reload_modules: True

auth-server-db:
  mysql_user.present:
    - name: {{ data['db-user'] }}
    - host: '%'
    - password: {{ data['db-password'] }}
    - connection_host: {{ data['db-host'] }}
    - connection_user: {{ db['user'] }}
    - connection_pass: {{ db['password'] }}
{% if 'socket' in db %}
    - connection_unix_socket: {{ db['socket'] }}
{% endif %}
    - require:
      - pip: auth-server-pip

  mysql_database.present:
    - name: {{ data['db-name'] }}
    - connection_host: {{ data['db-host'] }}
    - connection_user: {{ db['user'] }}
    - connection_pass: {{ db['password'] }}
{% if 'socket' in db %}
    - connection_unix_socket: {{ db['socket'] }}
{% endif %}
    - require:
      - pip: auth-server-pip

  mysql_grants.present:
    - grant: all
    - database: {{ data['db-name'] }}.*
    - user: {{ data['db-user'] }}
    - host: '%'
    - connection_host: {{ data['db-host'] }}
    - connection_user: {{ db['user'] }}
    - connection_pass: {{ db['password'] }}
{% if 'socket' in db %}
    - connection_unix_socket: {{ db['socket'] }}
{% endif %}
    - require:
      - mysql_user: auth-server-db
      - mysql_database: auth-server-db
      - pip: auth-server-pip

  mysql_query.run_file:
    - database: {{ data['db-name'] }}
    - query_file: salt://roles/auth-server/backsql_create.sql
    - connection_host: {{ data['db-host'] }}
    - connection_user: {{ db['user'] }}
    - connection_pass: {{ db['password'] }}
{% if 'socket' in db %}
    - connection_unix_socket: {{ db['socket'] }}
{% endif %}
    - onchanges:
      - mysql_database: auth-server-db

auth-server-slapd-config:
  file.managed:
    - name: /etc/ldap/slapd.conf
    - template: jinja
    - source:
      - salt://roles/auth-server/slapd.conf

auth-server-slapd-service:
  service.running:
    - name: slapd
    - enable: True
    - watch:
      - file: auth-server-slapd-config
