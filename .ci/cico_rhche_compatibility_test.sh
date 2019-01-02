#!/usr/bin/env bash
# Copyright (c) 2018 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

function getTagWithShortHashes() {
	#Get last commit short hash from upstream che
	upstream_branch=$(echo $CHE_VERSION | cut -d"." -f 1,2).x
	longHashUpstream=$(curl -s https://api.github.com/repos/eclipse/che/commits/$upstream_branch | jq .sha)
	if [ "$longHashUpstream" == "null" ]; then
		exit 1
	else
		shortHashUpstream=${longHashUpstream:1:7}
	fi
	
	#Get last commit short has from rh-hce branch 
	longHashDownstream=$(git log | grep -m 1 commit | head -1 | cut -d" " -f 2)
	shortHashDownstream=${longHashDownstream:0:7}
	echo "upstream-check-$shortHashUpstream-$shortHashDownstream"
}

set -e

export USE_CHE_LATEST_SNAPSHOT="true"
export BASEDIR=$(pwd)
export DEV_CLUSTER_URL=https://devtools-dev.ext.devshift.net:8443/
CHE_VERSION=$(curl -s https://raw.githubusercontent.com/eclipse/che/master/pom.xml | grep "^    <version>.*</version>$" | awk -F'[><]' '{print $3}')
if [[ -z $CHE_VERSION ]]; then
	echo "FAILED to get che version. Finishing script."
	exit 1
fi

echo "********** Running compatibility test with upstream version of che: $CHE_VERSION **********"

#eval "$(./env-toolkit load -f jenkins-env.json -r \
#        ^DEVSHIFT_TAG_LEN$ \
#        ^QUAY_ \
#        ^KEYCLOAK \
#        ^BUILD_NUMBER$ \
#        ^JOB_NAME$ \
#        ^ghprbPullId$ \
#        ^RH_CHE)"
        
source ./config
source .ci/functional_tests_utils.sh

echo "Checking credentials:"
#checkAllCreds
echo "Installing dependencies:"
#installDependencies

BRANCH="upstream-check-$CHE_VERSION"

set +e
git checkout $BRANCH
set -e
if [ $? -eq 0 ]; then 
	echo "Branch $BRANCH found - rebasing."
	git rebase origin/master $BRANCH || echo "Unable to rebase on master - please resolve conflicts." && exit 1
else 
	echo "Branch $BRANCH not found - creating new one."
	git checkout -b $BRANCH
	
	#change version of used che
	echo ">>> change upstream version to: $CHE_VERSION"
#	scl enable rh-maven33 rh-nodejs8 "mvn versions:update-parent  versions:commit -DallowSnapshots=true -DparentVersion=[${CHE_VERSION}] -U"
fi

export DOCKER_IMAGE_TAG="upstream-check-latest"	
export DOCKER_IMAGE_TAG_WITH_SHORTHASHES=$(getTagWithShortHashes)
export PROJECT_NAMESPACE=compatibility-check

echo "before exit"
exit 

#set values needed for creating PR
RELATED_PR_TITLE="Update to $(echo $CHE_VERSION | cut -d'-' -f 1)"
PR_BODY="Automatically created pull request for tracking changes of version $CHE_VERSION."
PR_HEAD="$BRANCH"
PR_BASE="master"

PULL_REQUESTS=$(curl -s https://api.github.com/repos/redhat-developer/rh-che/pulls?state=open | jq '.[].title')
if [ $? -eq 0 ]; then
  echo "Getting list of open PRs successful."
else
  echo "Retrieving open pull requests failed with exit code $?"
  exit $?
fi

#check if pull request exists
PR_EXISTS=1
while read -r pr_title
do
  if [[ "$pr_title" == "$RELATED_PR_TITLE" ]]; then
  	echo "Pull request for tracking changes of version $CHE_VERSION has been already created."
	PR_EXISTS=0
	break
  fi
done <<< "$PullRequests"

#if PR does not exist, create it
if [[ $PR_EXISTS -eq 1 ]]; then
	echo "Pull request for tracking changes of version $CHE_VERSION was not found - creating new one."
	
	#add changes and push branch
	git diff --exit-code
	if [ $? == 0 ]; then
		echo "Nothing to commit, continue."
	else
		echo "Changes found. Commit and push them before creating PR."
		git add -u
		git commit -m"Changing version of parent che to $CHE_VERSION"
		git push origin $BRANCH
	fi
	#TODO add token there
	curl -X POST -H "Content-Type: application/json" --data '{"title":"$RELATED_PR_TITLE", "body":"$PR_BODY", "head":"$PR_HEAD", "base":"$PR_BASE"}' -u osiotest:$RH_CHE_GITHUB_TESTING_TOKEN https://api.github.com/repos/redhat-developer/rh-che/pulls
fi

echo "Running compatibility check with build, deploy to dev cluster and test."
.ci/cico_build_deploy_test_rhche.sh

