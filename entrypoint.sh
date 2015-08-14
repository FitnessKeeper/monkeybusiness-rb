#!/bin/bash

set -o nounset

if [ -r .env ]; then
  . .env
fi

APPDIR=${MONKEYBUSINESS_APPDIR}
APPPORT=${MONKEYBUSINESS_APPPORT}

cd ${APPDIR}

# start Sidekiq
bundle exec sidekiq -r ./lib/monkeybusiness/scheduler.rb &

# start Unicorn
bundle exec unicorn -p ${APPPORT}
