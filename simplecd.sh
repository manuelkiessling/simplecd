#!/bin/bash

# Main script for Simple Continuous Delivery


PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/bin


# Function #################################################################

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
  rm -f $CONTROLFILE
  exit 1
}

log () {
  LOG="$LOG

$1"
}

mail_log () {
  if [ -f $REPODIR/$SCRIPTSDIR/logreceivers.txt ]; then
    echo "$LOG" > $WORKINGDIR/log.$HASH
    while read MR; do
      echo "Mailing log of this run to $MR..."
      mail -aFrom:simplecd@`hostname --fqdn` -s "[simplecd][$1] $REPO - $SOURCE" $MR < $WORKINGDIR/log.$HASH
    done < $REPODIR/$SCRIPTSDIR/logreceivers.txt
  fi
}

run_project_script () {
  STATUS=0
  echo "Starting project's $1 script..."
  log ""
  log "Output of project's $1 script:
#######################################"
  echo ""
  OUTPUT=`$REPODIR/$SCRIPTSDIR/$1 $MODE $REPODIR $CHECKOUTSOURCE 2>&1`
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

MODE=$1 # "branch" or "tag"
SOURCE=$2
REPO=$3

if [ "$MODE" = "" ]; then
  abort "Missing parameter MODE. Aborting..."
fi

if [ "$REPO" = "" ]; then
  abort "Missing parameter REPO. Aborting..."
fi

if [ "$SOURCE" = "" ]; then
  abort "Missing parameter SOURCE. Aborting..."
fi


if [ -x /sbin/md5 ]; then
  MD5BIN=/sbin/md5
else
  MD5BIN=/usr/bin/md5sum
fi

HASH=`echo "$0 $MODE $REPO $SOURCE" | $MD5BIN | cut -d" " -f1`
WORKINGDIR=/var/tmp/simplecd
PROJECTSDIR=$WORKINGDIR/projects
REPODIR=/var/tmp/simplecd/projects/$HASH
CONTROLFILE=/var/tmp/simplecd/controlfile.$HASH

# Did the user provide the parameter "reset"? In this case
# we remove everything we know about the given repo/branch combination

if [ "$4" = "reset" ]; then
  echo "Resetting SimpleCD environment for mode $MODE, repo $REPO, source $SOURCE"
  if [ "$MODE" = "branch" ]; then
    rm -f $WORKINGDIR/last_commit_id.$HASH
  fi
  if [ "$MODE" = "tag" ]; then
    rm -f $WORKINGDIR/last_tag.$HASH
  fi
  rm -f $WORKINGDIR/log.$HASH
  rm -rf $REPODIR
  rm -f $CONTROLFILE
  echo "done."
  exit 0
fi
URLPREFIX=$4

# Is another process for this mode, repo and source running?

if [ -f $CONTROLFILE ]; then
  echo "Because the control file $CONTROLFILE exists, I assume that another instance is still running. Aborting..."
  exit 1
fi

# Prepare and check the environment

mkdir -p $PROJECTSDIR

if [ ! -w $PROJECTSDIR ]; then
  abort "Cannot write to directory $PROJECTSDIR. Aborting..."
fi

# Create control file so no other runs are started in parallel

touch $CONTROLFILE


# Let's go

echo ""
echo "Starting delivery of source $SOURCE from repo $REPO in mode $MODE, hash of this run is $HASH"
echo ""
log "Log for delivery of source $SOURCE from repo $REPO in mode $MODE, hash of this run was $HASH"

rm -rf $REPODIR
git clone $REPO $REPODIR 2>&1 | while IFS= read -r line;do echo " [GIT CLONE] $line";done
cd $REPODIR
git fetch


# Resolve source and check for new content

if [ "$MODE" = "branch" ]; then
  RESOLVEDSOURCE=refs/heads/$SOURCE
  # Check if a new commit id is in the remote repo
  LASTCOMMITID=`cat $WORKINGDIR/last_commit_id.$HASH 2> /dev/null`
  REMOTECOMMITID=`git ls-remote $REPO $RESOLVEDSOURCE | cut -f1`
  if [ "$LASTCOMMITID" = "$REMOTECOMMITID" ]; then
    echo "Remote commit id ($REMOTECOMMITID) has not changed since last run, won't deliver. Aborting..."
    rm -f $CONTROLFILE
    exit 0
  fi
  CURRENTCOMMITID=`git log -n 1 $RESOLVEDSOURCE --pretty=format:"%H"`
  echo $CURRENTCOMMITID > $WORKINGDIR/last_commit_id.$HASH
  CHECKOUTSOURCE=$SOURCE
fi
if [ "$MODE" = "tag" ]; then
  # Check if a new tag matching the pattern exists
  LASTTAG=`cat $WORKINGDIR/last_tag.$HASH 2> /dev/null`
  LASTEXISTINGTAG=`git tag -l $SOURCE | tail -n1`
  if [ "$LASTTAG" = "$LASTEXISTINGTAG" ]; then
    echo "No tag newer than '$LASTTAG' found, won't deliver. Aborting..."
    rm -f $CONTROLFILE
    exit 0
  fi
  CURRENTCOMMITID=$LASTEXISTINGTAG
  echo $LASTEXISTINGTAG > $WORKINGDIR/last_tag.$HASH
  RESOLVEDSOURCE=refs/tags/$LASTEXISTINGTAG
  CHECKOUTSOURCE=$LASTEXISTINGTAG
fi


# Checkout the source

git checkout $CHECKOUTSOURCE 2>&1 | while IFS= read -r line;do echo " [GIT CHECKOUT] $line";done


# Create summary

echo ""
echo "This is what's going to be delivered:"
SUMMARY="
 Repository: $REPO
     Source: $MODE $RESOLVEDSOURCE
     Commit: $URLPREFIX$CURRENTCOMMITID
         by: `git log -n 1 $CURRENTCOMMITID --pretty=format:'%an'`
         at: `git log -n 1 $CURRENTCOMMITID --pretty=format:'%aD'`
        msg: `git log -n 1 $CURRENTCOMMITID --pretty=format:'%s'`"
echo "$SUMMARY"
log "$SUMMARY"
echo ""


SCRIPTSDIR=_simplecd
source $REPODIR/.simplecd


## Run delivery steps from repository ##########################################

for STEPFILENAME in `ls $REPODIR/$SCRIPTSDIR/[0-9][0-9]-* | sort | rev | cut -d"/" -f1 | rev`; do
  run_project_script $STEPFILENAME
done


# Clean up the control file and finish

echo ""

shutdown "Delivery finished. Exiting..."
