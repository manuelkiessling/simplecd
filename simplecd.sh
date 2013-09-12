#!/bin/bash

# Main script for Simple Continuous Delivery


PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/bin


# Functions ####################################################################

shutdown () {
  echo $1
  echo ""
  mail_log "success"
  rm -f $CONTROLFILE
  exit 0
}

abort () { 
  echo $1
  echo ""
  mail_log "failure"
  rm $CONTROLFILE
  exit 1
}

log () {
  LOG="$LOG

$1"
}

mail_log () {
  if [ -f $REPODIR/_simplecd/logreceivers.txt ]; then
    echo "$LOG" > $WORKINGDIR/log.$HASH
    while read MR; do
      echo "Mailing log of this run to $MR..."
      mail -aFrom:simplecd@example.com -s "[simplecd][$1] $REPO - $BRANCH" $MR < $WORKINGDIR/log.$HASH
    done < $REPODIR/_simplecd/logreceivers.txt
  fi
}

run_project_script () {
  STATUS=0
  echo "Starting project's $1 script..."
  log ""
  log "Output of project's $1 script:
#######################################"
  echo ""
  OUTPUT=`$REPODIR/_simplecd/$1 $REPODIR`
  STATUS=$?
  echo "$OUTPUT"
  log "$OUTPUT"
  echo ""
  echo "Finished executing project's $1 script."

  if [ ! $STATUS -eq 0 ]; then
    abort "Error while executing project's $1 script. Aborting..."
  fi

  echo ""
}


# Main routine #################################################################

REPO=$1
BRANCH=$2

HASH=`echo "$0 $REPO $BRANCH" | md5sum | cut -d" " -f1`
WORKINGDIR=/var/tmp/simplecd
PROJECTSDIR=$WORKINGDIR/projects
REPODIR=/var/tmp/simplecd/projects/$HASH
CONTROLFILE=/var/tmp/simplecd/controlfile.$HASH


# Did the user provide the parameter "reset"? In this case
# we remove everything we know about the given repo/branch combination

if [ "$3" = "reset" ]; then
  echo "Resetting SimpleCD environment for repo $REPO, branch $BRANCH"
  rm -f $WORKINGDIR/last_commit_id.$HASH
  rm -f $WORKINGDIR/log.$HASH
  rm -rf $REPODIR
  rm -f $CONTROLFILE
  echo "done."
  exit 0
fi
URLPREFIX=$3

# Is another process for this repo and branch running?

if [ -f $CONTROLFILE ]; then
  echo "Because the control file $CONTROLFILE exists, I assume that another instance is still running. Aborting..."
  exit 1
fi


# Create control file so no other runs are started in parallel

touch $CONTROLFILE


# Let's go

echo ""
echo "Starting delivery of branch $BRANCH from repo $REPO, hash of this run is $HASH"
echo ""
log "Log for delivery of branch $BRANCH from repo $REPO, hash of this run was $HASH"

# Prepare and check the environment

mkdir -p $PROJECTSDIR

if [ ! -w $PROJECTSDIR ]; then
  abort "Cannot write to directory $PROJECTSDIR. Aborting..."
fi


# Check if a new commit id is in the remote repo

LASTCOMMITID=`cat $WORKINGDIR/last_commit_id.$HASH 2> /dev/null`
REMOTECOMMITID=`git ls-remote $REPO refs/heads/$BRANCH | cut -f1`

if [ "$LASTCOMMITID" = "$REMOTECOMMITID" ]; then
  echo "Remote commit id ($REMOTECOMMITID) has not changed since last run, won't deliver. Aborting..."
  exit 0
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
SUMMARY="
 Repository: $REPO
     Branch: $BRANCH
     Commit: $URLPREFIX$CURRENTCOMMITID
         by: `git log -n 1 refs/heads/$BRANCH --pretty=format:'%an'`
         at: `git log -n 1 refs/heads/$BRANCH --pretty=format:'%aD'`
        msg: `git log -n 1 refs/heads/$BRANCH --pretty=format:'%s'`"
echo "$SUMMARY"
log "$SUMMARY"
echo ""


## Run delivery steps from repository ##########################################

for STEPFILENAME in `ls $REPODIR/_simplecd/[0-9][0-9]-* | sort | rev | cut -d"/" -f1 | rev`; do
  run_project_script $STEPFILENAME
done


# Clean up the control file and finish

echo ""

shutdown "Delivery finished. Exiting..."
