#!/bin/bash
set -e

ORG=${ORG:-hsldevcom}
PROJECT_NAME=${PROJECT_NAME:-hsl-jore-postgis}
DOCKER_TAG=${ORG}/${PROJECT_NAME}:history

docker build --build-arg INCLUDE_JORE_STATIC=false -t $DOCKER_TAG .
docker push $DOCKER_TAG
