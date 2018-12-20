#!/usr/bin/env bash
# Copyright (c) 2018 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

export PR_CHECK_BUILD="true"
export BASEDIR=$(pwd)
export DEV_CLUSTER_URL=https://devtools-dev.ext.devshift.net:8443/
export OC_VERSION=3.10.85

mkdir emptydir
ls -la ./artifacts.key
chmod 600 ./artifacts.key
chown root ./artifacts.key

#rsync --password-file=./artifacts.key -PHva --delete --include=functional-tests.log --exclude=* emptydir/ devtools@artifacts.ci.centos.org::devtools/rhche
rsync --password-file=./artifacts.key -PHva --delete emptydir/ devtools@artifacts.ci.centos.org::devtools/rhche/screenshots
rsync --password-file=./artifacts.key -PHva --delete --include=screenshots --exclude=* emptydir/ devtools@artifacts.ci.centos.org::devtools/rhche

rsync --password-file=./artifacts.key -PHva --delete --include=README.md --exclude=* emptydir/ devtools@artifacts.ci.centos.org::devtools/
exit


eval "$(./env-toolkit load -f jenkins-env.json -r \
        ^DEVSHIFT_TAG_LEN$ \
        ^QUAY_ \
        ^KEYCLOAK \
        ^BUILD_NUMBER$ \
        ^JOB_NAME$ \
        ^ghprbPullId$ \
        ^RH_CHE)"

source ./config
# Provides methods:
#   checkAllCreds
#   installDependencies
#   archiveArtifacts
source .ci/functional_tests_utils.sh

echo "Checking credentials:"
checkAllCreds
echo "Installing dependencies:"
installDependencies

export PROJECT_NAMESPACE=prcheck-${RH_PULL_REQUEST_ID}
export DOCKER_IMAGE_TAG="${RH_TAG_DIST_SUFFIX}"-"${RH_PULL_REQUEST_ID}"

echo "Running ${JOB_NAME} PR: #${RH_PULL_REQUEST_ID}, build number #${BUILD_NUMBER}"
.ci/cico_build_deploy_test_rhche.sh
