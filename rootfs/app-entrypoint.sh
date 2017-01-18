#!/bin/bash
set -e

source /functions.sh

INIT_SEM=/tmp/initialized.sem
PACKAGE_FILE=/app/package.json

function initialize {
    # Package can be "installed" or "unpacked"
    status=`nami inspect $1`
    if [[ "$status" == *'"lifecycle": "unpacked"'* ]]; then
        # Clean up inputs
        inputs=""
        if [[ -f /$1-inputs.json ]]; then
            inputs=--inputs-file=/$1-inputs.json
        fi
        nami initialize $1 $inputs
    fi
}

if [ "$1" == npm ] && [ "$2" == "start" -o "$2" == "run" ]; then
  initialize express
  wait_for_db

  if ! app_present; then
    log "Creating express application"
    express . -f
    add_database_support
    add_sample_code
  fi

  add_dockerfile

  install_packages

  if ! fresh_container; then
    echo "#########################################################################"
    echo "                                                                       "
    echo " App initialization skipped:"
    echo " Delete the file $INIT_SEM and restart the container to reinitialize"
    echo " You can alternatively run specific commands using docker-compose exec"
    echo " e.g docker-compose exec myapp npm install angular"
    echo "                                                                       "
    echo "#########################################################################"
  else
    # Perform any app initialization tasks here.
    log "Initialization finished"
  fi

  migrate_db

  touch $INIT_SEM
elif [ "$1" == tail ] && [ "$2" == "-f"] && [ "$3" == "/dev/null" ]; then
  initialize express
fi

exec /entrypoint.sh "$@"
