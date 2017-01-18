#!/bin/bash

fresh_container() {
  [ ! -f $INIT_SEM ]
}

app_present() {
  [ -f package.json ]
}

dependencies_up_to_date() {
  # It it up to date if the package file is older than
  # the last time the container was initialized
  [ ! $PACKAGE_FILE -nt $INIT_SEM ]
}

database_tier_exists() {
  [ -n "$(getent hosts mongodb mariadb postgresql)" ]
}

__wait_for_db() {
  local host=$1
  local port=$2
  local ip_address=$(getent hosts $1 | awk '{ print $1 }')

  log "Connecting to at $host server at $ip_address:$port"

  counter=0
  until nc -z $ip_address $port; do
    counter=$((counter+1))
    if [ $counter == 10 ]; then
      log "Error: Couldn't connect to $host server."
      return 1
    fi
    log "Trying to connect to $host server at $ip_address:$port. Attempt $counter."
    sleep 5
  done
  log "Connected to $host server"
}

wait_for_db() {
  if ! [[ -n $SKIP_DB_WAIT && $SKIP_DB_WAIT -gt 0 ]] && database_tier_exists ; then
    if getent hosts mongodb >/dev/null; then
      __wait_for_db mongodb 27017
    fi

    if getent hosts mariadb >/dev/null; then
      __wait_for_db mariadb 3306
    fi

    if getent hosts postgresql >/dev/null; then
      __wait_for_db postgresql 5432
    fi
  fi
}

add_database_support() {
  if database_tier_exists; then
    if getent hosts mongodb >/dev/null && ! npm ls mongodb >/dev/null; then
      npm install --save mongodb
    fi

    if getent hosts mariadb >/dev/null && ! npm ls mysql >/dev/null; then
      npm install --save mysql
    fi

    if getent hosts postgresql >/dev/null && ! npm ls pg pg-hstore >/dev/null; then
      npm install --save pg pg-hstore
    fi
  fi
}

add_sample_code() {
  if ! [[ -n $SKIP_SAMPLE_CODE && $SKIP_SAMPLE_CODE -gt 0 ]]; then
    log "Adding dist samples"
    cp -r /dist/samples .
  fi
}

add_dockerfile() {
  if [[ ! -f Dockerfile ]]; then
    cp -r /dist/Dockerfile.tpl Dockerfile
    sed -i 's/{{BITNAMI_IMAGE_VERSION}}/'"$BITNAMI_IMAGE_VERSION"'/g' Dockerfile
    [[ ! -f bower.json ]] && sed -i '/^RUN bower install/d' Dockerfile
  fi

  if [[ ! -f .dockerignore ]]; then
    cp -r /dist/.dockerignore .
  fi
}

install_packages() {
  if ! dependencies_up_to_date; then
    if ! [[ -n $SKIP_NPM_INSTALL && $SKIP_NPM_INSTALL -gt 0 ]] && [[ -f package.json ]]; then
      log "Installing npm packages"
      npm install
    fi

    if ! [[ -n $SKIP_BOWER_INSTALL && $SKIP_BOWER_INSTALL -gt 0 ]] && [[ -f bower.json ]]; then
      log "Installing bower packages"
      bower install
    fi
  fi
}

migrate_db() {
  if ! [[ -n $SKIP_DB_MIGRATE && $SKIP_DB_MIGRATE -gt 0 ]] && [[ -f .sequelizerc ]]; then
    log "Applying database migrations (sequelize db:migrate)"
    sequelize db:migrate
  fi
}

log () {
  echo -e "\033[0;33m$(date "+%H:%M:%S")\033[0;37m ==> $1."
}
