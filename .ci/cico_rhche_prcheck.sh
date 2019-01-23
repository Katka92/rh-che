#!/usr/bin/env bash
# Copyright (c) 2018 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

export PR_CHECK_BUILD="true"
export BASEDIR=$(pwd)
export DEV_CLUSTER_URL=https://devtools-dev.ext.devshift.net:8443/

eval "$(./env-toolkit load -f jenkins-env.json -r \
        ^DEVSHIFT_TAG_LEN$ \
        ^QUAY_ \
        ^KEYCLOAK \
        ^BUILD_NUMBER$ \
        ^JOB_NAME$ \
        ^ghprbPullId$ \
        ^RH_CHE)"

source ./config
source .ci/functional_tests_utils.sh

echo "Checking credentials"
checkAllCreds
echo "Installing dependencies"
installDependencies

export PROJECT_NAMESPACE=prcheck-${RH_PULL_REQUEST_ID}
export DOCKER_IMAGE_TAG="${RH_TAG_DIST_SUFFIX}"-"${RH_PULL_REQUEST_ID}"

export AUTH_ENDPOINT="https://auth.prod-preview.openshift.io"
export RHCHE_TOKEN_URL="https://sso.prod-preivew.openshift.io/auth/realms/fabric8/broker"
export USERNAME=$RH_CHE_AUTOMATION_CHE_PREVIEW_USERNAME
export PASSWORD=$RH_CHE_AUTOMATION_CHE_PREVIEW_PASSWORD
export EMAIL=$RH_CHE_AUTOMATION_CHE_PREVIEW_EMAIL
export HOST_URL=rhche-$PROJECT_NAMESPACE.devtools-dev.ext.devshift.net/
export MOUNT_PATH=$(pwd)

echo "Running ${JOB_NAME} PR: #${RH_PULL_REQUEST_ID}, build number #${BUILD_NUMBER}"
.ci/cico_build_deploy_test_rhche.sh
