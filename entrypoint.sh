#!/bin/bash

APPDIR='/usr/src/app'
APPPORT='9090'

cd ${APPDIR}

# start Sidekiq
bundle exec sidekiq -r ./lib/monkeybusiness/scheduler.rb &

# start Unicorn
bundle exec unicorn -p ${APPPORT}
