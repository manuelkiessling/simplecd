#!/bin/bash

# Main script for Simple Continuous Delivery

PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/bin


# Functions #################################################################

shutdown () {
  echo $1
  echo ""
  prepend_to_maillog "Result: success."
  send_maillog "success"
  rm -f $CONTROLFILE
  exit 0
}

abort () {
  echo $1
  echo ""
  prepend_to_maillog "$1"
  prepend_to_maillog "Result: failure."
  send_maillog "failure"
  rm -f $CONTROLFILE
  exit 1
}


prepend_to_maillog () {
  MAILLOG="$1

$MAILLOG"
}

append_to_maillog () {
  MAILLOG="$MAILLOG

$1"
}

send_maillog () {
  if [ -f $REPODIR/$SCRIPTSDIR/logreceivers.txt ]; then
    echo "$SUMMARY"                      > $WORKINGDIR/maillog.$HASH
    echo ""                             >> $WORKINGDIR/maillog.$HASH
    echo ""                             >> $WORKINGDIR/maillog.$HASH
    echo "Last 100 lines of log output" >> $WORKINGDIR/maillog.$HASH
    echo "############################" >> $WORKINGDIR/maillog.$HASH
    echo ""                             >> $WORKINGDIR/maillog.$HASH
    echo "$MAILLOG" | tail -100         >> $WORKINGDIR/maillog.$HASH
    echo ""                             >> $WORKINGDIR/maillog.$HASH
    echo ""                             >> $WORKINGDIR/maillog.$HASH
    echo "Full log output"              >> $WORKINGDIR/maillog.$HASH
    echo "###############"              >> $WORKINGDIR/maillog.$HASH
    echo ""                             >> $WORKINGDIR/maillog.$HASH
    echo "$MAILLOG"                     >> $WORKINGDIR/maillog.$HASH
    while read MAILRECEIVER; do
      echo "Mailing log of this run to $MAILRECEIVER..."
      mail -aFrom:`whoami`@`hostname --fqdn` -s "[simplecd][$1] $REPO - $SOURCE" $MAILRECEIVER < $WORKINGDIR/maillog.$HASH
    done < $REPODIR/$SCRIPTSDIR/logreceivers.txt
  fi
}

run_project_script () {
  STATUS=0
  echo "Starting project's $1 script..."
  append_to_maillog ""
  append_to_maillog "Output of project's $1 script:
#######################################"
  echo ""
  $REPODIR/$SCRIPTSDIR/$1 $MODE $REPODIR $CHECKOUTSOURCE > >(tee -a $WORKINGDIR/$HASH.script.$1.log) 2> >(tee -a $WORKINGDIR/$HASH.script.$1.log >&2)
  STATUS=$?
  OUTPUT=`cat $WORKINGDIR/$HASH.script.$1.log`
  rm $WORKINGDIR/$HASH.script.$1.log
  append_to_maillog "$OUTPUT"
  echo ""
  echo "Finished executing project's $1 script."

  if [ ! $STATUS -eq 0 ]; then
    if [ -x "$REPODIR/$SCRIPTSDIR/on-project-script-error" ]; then
      echo "Error while executing project's $1 script. Executing on-project-script-error script..."
      append_to_maillog "Error while executing project's $1 script. Executing on-project-script-error script..."
      $REPODIR/$SCRIPTSDIR/on-project-script-error > >(tee -a $WORKINGDIR/$HASH.script.on-project-script-error.log) 2> >(tee -a $WORKINGDIR/$HASH.script.on-project-script-error.log >&2)
      OUTPUT=`cat $WORKINGDIR/$HASH.script.on-project-script-error.log`
      rm $WORKINGDIR/$HASH.script.on-project-script-error.log
      append_to_maillog "$OUTPUT"
      echo ""
      echo "Finished executing project's on-project-script-error script."
    fi
    abort "Error while executing project's $1 script. Aborting..."
  fi

  echo ""
}


# Sanity checks #############################################################

# Verify that we have git

git --version > /dev/null 2>&1
if [ ! $? -eq 0 ]; then
  abort "Git not available. Aborting..."
fi

# Verify that we have a modern version of sort

echo "foo" | sort --version-sort > /dev/null 2>&1
if [ ! $? -eq 0 ]; then
  abort "Your version of sort does not support --version-sort. Aborting..."
fi


# Main routine #################################################################

MODE=$1 # "branch" or "tag"
SOURCE=$2
REPO=$3

if [ "$4" = "reset" ]; then
    DORESET="yes"
elif [ "$4" = "--tag-on-success" ]; then
    TAGONSUCCESS="yes"
    DORESET="no"
elif [ "$4" != "" ]; then
    URLPREFIX=$4
    DORESET="no"
fi

if [ "$5" = "--tag-on-success" ]; then
    TAGONSUCCESS="yes"
fi


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
REPODIR=$PROJECTSDIR/$HASH
CONTROLFILE=$WORKINGDIR/controlfile.$HASH
LASTCOMMITIDFILE=$WORKINGDIR/last_commit_id.$HASH
LASTTAGFILE=$WORKINGDIR/last_tag.$HASH

# Did the user provide the parameter "reset"? In this case
# we remove everything we know about the given repo/branch combination

if [ "$DORESET" = "yes" ]; then
  echo "Resetting SimpleCD environment for mode $MODE, repo $REPO, source $SOURCE"
  if [ "$MODE" = "branch" ]; then
    rm -f $WORKINGDIR/last_commit_id.$HASH
  fi
  if [ "$MODE" = "tag" ]; then
    rm -f $WORKINGDIR/last_tag.$HASH
  fi
  rm -f $WORKINGDIR/maillog.$HASH
  rm -rf $REPODIR
  rm -f $CONTROLFILE
  echo "done."
  exit 0
fi

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
append_to_maillog "Log for delivery of source $SOURCE from repo $REPO in mode $MODE, hash of this run was $HASH"


# Resolve source and check for new content

if [ "$MODE" = "branch" ]; then
  RESOLVEDSOURCE=refs/heads/$SOURCE
  # Check if a new commit id is in the remote repo
  LASTCOMMITID=`cat $LASTCOMMITIDFILE 2> /dev/null`
  REMOTECOMMITID=`git ls-remote $REPO $RESOLVEDSOURCE | cut -f1`
  if [ "$LASTCOMMITID" = "$REMOTECOMMITID" ]; then
    echo "Remote commit id ($REMOTECOMMITID) has not changed since last run, won't deliver. Aborting..."
    rm -f $CONTROLFILE
    exit 0
  fi
  if [ "" = "$REMOTECOMMITID" ]; then
    echo "Couldn't retrieve remote commit id, won't deliver. Aborting..."
    rm -f $CONTROLFILE
    exit 0
  fi
  append_to_maillog "Local known last commit id was $LASTCOMMITID, found $REMOTECOMMITID remotely."
  rm -rf $REPODIR
  git clone $REPO $REPODIR 2>&1 | while IFS= read -r line;do echo " [GIT CLONE] $line";done
  cd $REPODIR
  git fetch
  CURRENTCOMMITID=$REMOTECOMMITID
  echo $CURRENTCOMMITID > $LASTCOMMITIDFILE
  CHECKOUTSOURCE=$SOURCE
fi

if [ "$MODE" = "tag" ]; then
  # Check if a new tag matching the pattern exists
  LASTTAG=`cat $LASTTAGFILE 2> /dev/null`
  LASTEXISTINGTAG=`git ls-remote --tags $REPO $SOURCE | cut -f2 | sort --version-sort | cut -d/ -f3 | tail -n1`
  if [ "$LASTTAG" = "$LASTEXISTINGTAG" ]; then
    echo "No tag newer than '$LASTTAG' found, won't deliver. Aborting..."
    rm -f $CONTROLFILE
    exit 0
  fi
  if [ "" = "$LASTEXISTINGTAG" ]; then
    echo "Couldn't retrieve remote tag, won't deliver. Aborting..."
    rm -f $CONTROLFILE
    exit 0
  fi
  append_to_maillog "Local known last tag was $LASTTAG, found $LASTEXISTINGTAG remotely."
  rm -rf $REPODIR
  git clone $REPO $REPODIR 2>&1 | while IFS= read -r line;do echo " [GIT CLONE] $line";done
  cd $REPODIR
  git fetch
  CURRENTCOMMITID=$LASTEXISTINGTAG
  echo $LASTEXISTINGTAG > $LASTTAGFILE
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
echo ""


SCRIPTSDIR=_simplecd
source $REPODIR/.simplecd


## Run delivery steps from repository ##########################################

for STEPFILENAME in `ls $REPODIR/$SCRIPTSDIR/[0-9][0-9]-* | sort | rev | cut -d"/" -f1 | rev`; do
  run_project_script $STEPFILENAME
done


# Tag the rolled out commit

if [ "$TAGONSUCCESS" = "yes" ]; then
  TAGNAME="simplecd-rollout-`date --iso-8601=seconds | tr : _`"
  TAGMESSAGE="SimpleCD rollout on `date --rfc-2822`."
  git tag -a $TAGNAME -m "$TAGMESSAGE" $CURRENTCOMMITID
  git push origin $TAGNAME
fi


# Clean up the control file and finish

echo ""

shutdown "Delivery finished. Exiting..."
