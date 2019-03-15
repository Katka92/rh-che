#!/usr/bin/env bash

# Provides methods:
#   checkAllCreds
#   installDependencies
#   archiveArtifacts
source .ci/functional_tests_utils.sh

function printHelp {
	YELLOW="\\033[93;1m"
	WHITE="\\033[0;1m"
	GREEN="\\033[32;1m"
	NC="\\033[0m" # No Color
	
	echo -e "${YELLOW}$(basename "$0") ${WHITE}[-u <username>] [-p <passwd>] [-m <email>] [-r <url>]" 
	echo -e "\n${NC}Script for running functional tests against production or prod-preview environment."
	echo -e "${GREEN}Mandatory parameters:${WHITE}"
	echo -e "-u    username for openshift account"
	echo -e "-p    password for openshift account"
	echo -e "-m    email for openshift account"
	echo -e "-r    URL of Rh-che"
	echo -e "${GREEN}Parameters preset for production env:${NC}"
	echo -e "-i    port (preset to 443)"
	echo -e "-j    URL for obtaining Rh-che token (preset to https://sso.openshift.io/auth/realms/fabric8/broker)"
	echo -e "-o    authentication endpoint (preset to https://auth.openshift.io)"
	echo -e "-s    local path to dir for storing screenshots (preset to /root/logs/screenshots)"
	echo -e "-t    protocol (preset to https)"
	echo -e "${GREEN}Other parameters that can be changed:${NC}"
	echo -e "-k    test suite to be executed (preset to simpleTestSuite.xml"
	echo -e "-l    path to local dir for storing logs (preset to /root/payload/logs)"
	echo -e "-v    local path from where to mount rh-che (if not set, code from Rh-che master is used)"
	
}

export LOG_DIR=/root/payload/logs
export RHCHE_SCREENSHOTS_DIR=/root/logs/screenshots
export PORT=443
export RHCHE_OPENSHIFT_TOKEN_URL="https://sso.openshift.io/auth/realms/fabric8/broker"
export TEST_SUITE="simpleTestSuite.xml"
export CHE_OSIO_AUTH_ENDPOINT="https://auth.openshift.io"
export HOST_URL="che.openshift.io"
export PROTOCOL="https"

while getopts "hi:j:k:l:m:o:p:r:s:t:u:v:" opt; do
  case $opt in
    h) printHelp
      exit 0
      ;;
    i) export PORT=$OPTARG
      ;;
    j) export RHCHE_OPENSHIFT_TOKEN_URL=$OPTARG
     ;;
    k) export TEST_SUITE=$OPTARG
     ;;
    l) export LOG_DIR=$OPTARG
      ;;
    m) export EMAIL=$OPTARG
      ;;
    o) export CHE_OSIO_AUTH_ENDPOINT=$OPTARG
      ;;
    p) export PASSWORD=$OPTARG
      ;;
    r) export HOST_URL=$OPTARG
      ;;
    s) export RHCHE_SCREENSHOTS_DIR=$OPTARG
      ;;
    t) export PROTOCOL=$OPTARG
      ;;
    u) export USERNAME=$OPTARG
      ;;
    v) export MOUNT_PATH=$OPTARG
      ;;
    \?)
      echo "\"$opt\" is an invalid option!"
      exit 1
      ;;
    :)
      echo "Option \"$opt\" needs an argument."
      exit 1
      ;;
  esac
done

if [[ -z $USERNAME || -z $PASSWORD || -z $EMAIL || -z $HOST_URL ]]; then
    echo "Please check if all credentials for user are set."
    exit 1
fi

#setting common parameters for docker
#change image once job for building prcheck image is fixed
DOCKER_COMMAND="docker run --name functional-tests-dep --privileged \
	           -v /var/run/docker.sock:/var/run/docker.sock \
	           -v $LOG_DIR:/root/logs \
	           -e \"RHCHE_SCREENSHOTS_DIR=$RHCHE_SCREENSHOTS_DIR\" \
	           -e \"RHCHE_ACC_USERNAME=$USERNAME\" \
	           -e \"RHCHE_ACC_EMAIL=$EMAIL\" \
	           -e \"RHCHE_ACC_PASSWORD=$PASSWORD\" \
	           -e \"RHCHE_HOST_URL=$HOST_URL\" \
	           -e \"CHE_OSIO_AUTH_ENDPOINT=$CHE_OSIO_AUTH_ENDPOINT\" \
	           -e \"RHCHE_HOST_PROTOCOL=$PROTOCOL\" \
	           -e \"RHCHE_PORT=$PORT\" \
	           -e \"RHCHE_OPENSHIFT_TOKEN_URL=$RHCHE_OPENSHIFT_TOKEN_URL\" \
	           -e \"TEST_SUITE=$TEST_SUITE\" "
	           
if [[ -n $MOUNT_PATH ]]; then
	DOCKER_COMMAND="${DOCKER_COMMAND} -v $MOUNT_PATH:/root/che/ "
fi

DOCKER_COMMAND="${DOCKER_COMMAND} quay.io/openshiftio/rhchestage-rh-che-functional-tests-dep"
eval "$DOCKER_COMMAND"
RESULT=$?

archiveArtifacts

if [[ $RESULT == 0 ]]; then
	echo "Tests result: SUCCESS"
else
	echo "Tests result: FAILURE"
fi

exit $RESULT	
