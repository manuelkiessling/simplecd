#!/bin/bash

# Main script for Simple Continuous Delivery

# Usage: simplecd.sh <repo-url> <branch>

# The following steps are executed:
#
# 1. Check if an instance of the given plan is already running, exit if yes
# 2. Compare local project checkout with remote repository - are there commits
#    on the remote repository that are newer than what we have locally? Exit
#    if no.
# 3. Pull the newest code from the remote repository
# 4. Run the script that deploys the code to staging (repo/_simplecd/deploy-staging.sh)
# 5. Does a Karma e2e config file exist? If yes, run it
# 6. Does a PHPUnit test suite exist? If yes, run it
# 7. If all tests are green, run the script that deploys the code to production (repo/_simplecd/deploy-production.sh)

PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/bin


# Perform some checks if everything we depend on is in place

if [ ! -w /var/tmp ]; then
  echo "Cannot write to directory /var/tmp. Exiting..."
  exit 2
fi

if [ ! -w /var/tmp/simplecd/projects ]; then
  echo "Cannot write to directory /var/tmp/simplecd/projects. Exiting..."
  exit 2
fi


CONTROLFILE=/var/tmp/simplecd.`echo "$0 $1 $2" | md5sum | cut -d" " -f1`

if [ -f $CONTROLFILE ]; then
  echo "Because the control file $CONTROLFILE exists, I assume that another instance is still running. Exiting..."
  exit 1
fi

# Create control file so no other runs are started in parallel
touch $CONTROLFILE


# Clean up the control file
echo $CONTROLFILE
rm -f $CONTROLFILE
