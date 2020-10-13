#!/bin/bash
set -e

ORG=${ORG:-hsldevcom}

read -p "Tag: " TAG

DOCKER_TAG=${TAG:-latest}
DOCKER_IMAGE=${ORG}/hsl-jore-postgis:${DOCKER_TAG}

docker build --build-arg INCLUDE_JORE_STATIC=true -t $DOCKER_IMAGE .
docker push $DOCKER_IMAGE
