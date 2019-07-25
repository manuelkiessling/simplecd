#!/usr/bin/env bash

# check if running server is an aws ec2 instance
SRVURI=$(curl http://169.254.169.254/latest/meta-data/public-ipv4) || SRVURI=$(hostname)

curl -X POST -H 'Content-type: application/json' \
 --data '{"text":"Hey there! I am building '$REPO' right now. You can follow my progress on: http://'$SRVURI'/'$UNIQUEDIR'. \n User: simplecd \n Passwort: S!mplYTh3B3st"}' \
  https://hooks.slack.com/services/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;