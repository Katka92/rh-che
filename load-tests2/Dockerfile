# Copyright (c) 2019 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM selenium/standalone-chrome:latest

ENV LANG=en_US.utf8 \
    DISPLAY=:99 \
    FABRIC8_USER_NAME=fabric8

USER "root"

RUN apt-get update && apt-get install && \
    apt-get install -y ftp && \
    apt-get install -y nodejs && \
    apt-get install -y npm && \
    npm install -g typescript && \
    apt-get install x11vnc ffmpeg -y

COPY e2e /tmp/e2e

# currently in tmp/e2e
RUN cd /tmp/e2e &&\
    npm run tsc

COPY e2e-saas /tmp/e2e-saas

RUN cd /tmp/e2e-saas &&\
    pwd &&\
    npm i ../e2e &&\
    tsc

WORKDIR /tmp/
COPY docker-entrypoint.sh /tmp/

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
