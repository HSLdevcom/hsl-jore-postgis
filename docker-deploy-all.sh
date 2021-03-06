#!/bin/bash
set -e

# Builds and deploys all images for the Azure environments

ORG=${ORG:-hsldevcom}

for TAG in dev stage production; do
  DOCKER_IMAGE=$ORG/hsl-jore-postgis:${TAG}

  docker build --build-arg INCLUDE_JORE_STATIC=true -t $DOCKER_IMAGE .
  docker push $DOCKER_IMAGE
done
