#!/bin/bash

exit_code=0

# Prepare config/database.yml to container app
rm spec/dummy/config/database.yml
ln -s ../../../../../config/database.yml spec/dummy/config/database.yml

if [ $# -eq 0 ] ; then
  echo "*** Running SOAP SERVER engine specs"
  bundle install  --jobs=3 --retry=3 | grep Installing
  bundle exec rspec spec/controllers
  exit_code+=$?

  echo "*** Running SOAP CLIENT specs"
  bundle exec rspec spec/lib
  exit_code+=$?
else
  echo "*** Run single test ($1)"

  if [ -e $1 ]; then
    bin/rspec $1
    exit_code+=$?
  else
    echo "**** Test not found"
    exit_code+=0
  fi
fi

exit $exit_code
