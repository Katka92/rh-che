#!/usr/bin/env bash
# Copyright (c) 2018 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#

#This script expects this environment variables set:
# CHE_TESTUSER_NAME, CHE_TESTUSER_PASSWORD, CHE_TESTUSER_EMAIL, RH_CHE_AUTOMATION_DEV_CLUSTER_SA_TOKEN


# --- SETTING ENVIRONMENT VARIABLES ---
export PROJECT=testing-rollout
export CHE_INFRASTRUCTURE=openshift
export CHE_MULTIUSER=true
export CHE_OFFLINE_TO_ACCESS_TOKEN_EXCHANGE_ENDPOINT=https://auth.prod-preview.openshift.io/api/token/refresh
export PROTOCOL=http
export OPENSHIFT_URL=https://devtools-dev.ext.devshift.net:8443
export RH_CHE_AUTOMATION_SERVER_DEPLOYMENT_URL=rhche-$PROJECT.devtools-dev.ext.devshift.net
export OPENSHIFT_TOKEN=$RH_CHE_AUTOMATION_DEV_CLUSTER_SA_TOKEN

eval "$(./env-toolkit load -f jenkins-env.json -r \
        ^DEVSHIFT_TAG_LEN$ \
        ^QUAY_ \
        ^KEYCLOAK \
        ^BUILD_NUMBER$ \
        ^JOB_NAME$ \
        ^RH_CHE \
	^CHE)"

# --- TESTING CREDENTIALS ---
echo "Running ${JOB_NAME} build number #${BUILD_NUMBER}, testing creds:"

CREDS_NOT_SET="false"

echo "test user name: $CHE_TESTUSER_NAME"

if [[ -z "${RH_CHE_AUTOMATION_DEV_CLUSTER_SA_TOKEN}" ]]; then
  echo "Developer cluster service account token is not set."
  CREDS_NOT_SET="true"
fi

if [[ -z "${CHE_TESTUSER_NAME}" || -z "${CHE_TESTUSER_PASSWORD}" ]]; then
  echo "Prod-preview credentials not set."
  CREDS_NOT_SET="true"
fi

if [ "${CREDS_NOT_SET}" = "true" ]; then
  echo "Failed to parse jenkins secure store credentials"
  exit 2
else
  echo "Credentials set successfully."
fi

# --- INSTALLING NEEDED SOFTWARE ---
# Getting core repos ready
yum install epel-release --assumeyes
yum update --assumeyes
yum install python-pip --assumeyes

# Test and show version
pip -V

# Getting dependencies ready
yum install --assumeyes \
            docker \
            jq \
            java-1.8.0-openjdk \
            java-1.8.0-openjdk-devel \
            centos-release-scl \
	    origin-clients

yum install --assumeyes \
            rh-maven33 

systemctl start docker
pip install yq


# --- DEPLOY RH-CHE ON DEVCLUSTER ---
if ./dev-scripts/deploy_custom_rh-che.sh -o "${RH_CHE_AUTOMATION_DEV_CLUSTER_SA_TOKEN}" \
                                         -e "${PROJECT}" \
                                         -z \
                                         -U;
then
  echo "Che successfully deployed."
else
  echo "Custom che deployment failed. Error code:$?"
  exit 4
fi

curl https://github.com/openshift/origin/releases/download/v3.9.0/openshift-origin-client-tools-v3.9.0-191fece-linux-64bit.tar.gz -o oc.tar.gz
tar --strip 1 -xzf oc.tar.gz -C /tmp

export OPENSHIFT_TOKEN=$RH_CHE_AUTOMATION_DEV_CLUSTER_SA_TOKEN
docker run --name functional-tests-dep --privileged \
           -v /var/run/docker.sock:/var/run/docker.sock \
           -v /tmp/oc/:/tmp/oc/ \
           -e "RHCHE_ACC_USERNAME=$CHE_TESTUSER_NAME" \
           -e "RHCHE_ACC_PASSWORD=$CHE_TESTUSER_PASSWORD" \
           -e "RHCHE_ACC_EMAIL=$CHE_TESTUSER_EMAIL" \
           -e "RHCHE_ACC_TOKEN=$CHE_TESTUSER_OFFLINE__TOKEN" \
           -e "CHE_OSIO_AUTH_ENDPOINT=https://auth.prod-preview.openshift.io" \
           -e "TEST_SUITE=rolloutTest.xml" \
	   -e "RHCHE_GITHUB_EXCHANGE=https://auth.prod-preview.openshift.io/api/token?for=https://github.com" \
	   -e "RHCHE_OPENSHIFT_TOKEN_URL=https://sso.prod-preview.openshift.io/auth/realms/fabric8/broker" \
	   -e "RHCHE_HOST_PROTOCOL=http" \
	   -e "RHCHE_HOST_URL=$RH_CHE_AUTOMATION_SERVER_DEPLOYMENT_URL" \
	   -e "OPENSHIFT_URL=$OPENSHIFT_URL" \
	   -e "OPENSHIFT_TOKEN=$OPENSHIFT_TOKEN" \
	   -e "OPENSHIFT_PROJECT=$PROJECT" \
           quay.io/openshiftio/rhchestage-rh-che-functional-tests-dep
RESULT=$?

if [[ $RESULT == 0 ]]; then
	echo "Tests result: SUCCESS"
else
	echo "Tests result: FAILURE"
fi

exit $RESULT
