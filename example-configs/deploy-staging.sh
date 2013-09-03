#!/bin/bash

# This file belongs in your project's repository as /_simplecd/deploy-staging.sh

# SimpleCD passes the path to the checkout as $1, e.g. /var/tmp/simplecd/projects/d472f461b335b3a731bc189065dc88d7

rsync -avc \
  --exclude ".git*"\
  --exclude "node_modules" \
  --exclude "_simplecd" \
  $1/ www-data@staging.example.com:/var/wwwroot/myproject/
