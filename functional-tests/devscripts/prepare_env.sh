#!/usr/bin/env bash

set -e
echo "Installing docker..."
yum install docker
systemctl start docker
docker pull quay.io/openshiftio/rhchestage-rh-che-functional-tests-dep