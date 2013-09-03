#!/bin/bash

# Main script for Simple Continuous Delivery

# Usage: simplecd.sh <repo-url> <branch>

# The following steps are executed:
#
# 1. Check if an instance of the given plan is already running, exit if yes
# 2. Check if the remote repo is newer than what was last delivered
# 3. Pull the newest code from the remote repository
# 4. Run the script that deploys the code to staging (repo/_simplecd/deploy-staging.sh)
# 5. Does a Karma e2e config file exists? If yes, run the Karma end-to-end tests
# 6. Does a PHPUnit test suite exist? If yes, run the PHP unit tests
# 7. If all tests are green, run the script that deploys the code to production (repo/_simplecd/deploy-production.sh)


# Functions ###################################################################

shutdown () {
  echo $1
  echo ""
  rm $CONTROLFILE
  exit 0
}

abort () { 
  echo $1
  echo ""
  rm $CONTROLFILE
  exit 1
} 


# Main routine ################################################################

PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/bin

REPO=$1
BRANCH=$2

HASH=`echo "$0 $REPO $BRANCH" | md5sum | cut -d" " -f1`
WORKINGDIR=/var/tmp/simplecd
PROJECTSDIR=$WORKINGDIR/projects
REPODIR=/var/tmp/simplecd/projects/$HASH


# Is another process for this repo and branch running?

CONTROLFILE=/var/tmp/simplecd/controlfile.$HASH
if [ -f $CONTROLFILE ]; then
  echo "Because the control file $CONTROLFILE exists, I assume that another instance is still running. Exiting..."
  exit 1
fi


# Create control file so no other runs are started in parallel

touch $CONTROLFILE


# Let's go

echo ""
echo "Starting delivery of branch $BRANCH from repo $REPO, hash of this run is $HASH"
echo ""


# Prepare and check the environment

mkdir -p $PROJECTSDIR

if [ ! -w $PROJECTSDIR ]; then
  abort "Cannot write to directory $PROJECTSDIR. Exiting..."
fi


# Check if a new commit id is in the remote repo

LASTCOMMITID=`cat $WORKINGDIR/last_commit_id.$HASH 2> /dev/null`
REMOTECOMMITID=`git ls-remote $REPO refs/heads/$BRANCH | cut -f1`

if [ "$LASTCOMMITID" = "$REMOTECOMMITID" ]; then
  shutdown "Remote commit id ($REMOTECOMMITID) has not changed since last run, won't deliver. Exiting..."
fi


# Clone the repo and checkout the branch

rm -rf $REPODIR
git clone $REPO $REPODIR 2>&1 | while IFS= read -r line;do echo " [GIT CLONE] $line";done
cd $REPODIR
git checkout $BRANCH 2>&1 | while IFS= read -r line;do echo " [GIT CHECKOUT] $line";done


# Store the current commit id

CURRENTCOMMITID=`git log -n 1 refs/heads/$BRANCH --pretty=format:"%H"`

echo $CURRENTCOMMITID > $WORKINGDIR/last_commit_id.$HASH

echo ""
echo "This is what's going to be delivered:"
echo " Repository: $REPO"
echo " Branch: $BRANCH"
echo " Commit: $CURRENTCOMMITID"
echo "     by: `git log -n 1 refs/heads/$BRANCH --pretty=format:'%an'`"
echo "     at: `git log -n 1 refs/heads/$BRANCH --pretty=format:'%aD'`"
echo "    msg: `git log -n 1 refs/heads/$BRANCH --pretty=format:'%s'`"
echo ""


# Deploy code to staging environment

if [ ! -f $REPODIR/_simplecd/deploy-staging.sh ]; then
  abort "Cannot find staging deploy script _simplecd/deploy-staging.sh in project repo. Exiting..."
fi

echo "Starting project's staging deployment script..."
echo ""
bash $REPODIR/_simplecd/deploy-staging.sh $REPODIR 2>&1 | while IFS= read -r line;do echo " [STAGING DEPLOY] $line";done
echo ""
echo "Finished executing project's staging deployment script."


# Prepare and run end-to-end tests

if [ ! -f $REPODIR/_simplecd/karma.e2e.conf.js ]; then
  echo "Cannot find Karma configuration file, not running e2e tests."
else
  echo "Preparing end-to-end test run with Karma."

  echo "Installing Node.js modules via NPM..."
  echo ""
  npm install 2>&1 | while IFS= read -r line;do echo " [NPM INSTALL] $line";done
  echo ""
  echo "done."

  echo "Starting Karma end-to-end test run..."
  echo ""
  karma start _simplecd/karma.e2e.conf.js
  KARMARUNSUCCESSFUL=$?
  echo ""
  echo "done."
fi

if [ ! $KARMARUNSUCCESSFUL -eq 0 ]; then
  abort "Karma end-to-end test run was not successful. Exiting..."
else
  echo "Karma end-to-end test run was successful."
fi

# Clean up the control file and finish

echo ""
shutdown "Delivery finished."
rm -f $CONTROLFILE
