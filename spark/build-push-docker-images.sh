#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script builds and pushes docker images when run from a release of Spark
# with Kubernetes support.

#declare -A path=( [spark-driver]=dockerfiles/driver/Dockerfile \
#                  [spark-executor]=dockerfiles/executor/Dockerfile \
#                  [spark-driver-py]=dockerfiles/driver-py/Dockerfile \
#                  [spark-executor-py]=dockerfiles/executor-py/Dockerfile \
#                  [spark-driver-r]=dockerfiles/driver-r/Dockerfile \
#                  [spark-executor-r]=dockerfiles/executor-r/Dockerfile \
#                  [spark-init]=dockerfiles/init-container/Dockerfile \
#                  [spark-shuffle]=dockerfiles/shuffle-service/Dockerfile \
#                  [spark-resource-staging-server]=dockerfiles/resource-staging-server/Dockerfile )

#function build {
#  docker build -t spark-base -f dockerfiles/spark-base/Dockerfile .
#  for image in "${!path[@]}"; do
#    docker build -t ${REPO}/$image:${TAG} -f ${path[$image]} .
#  done
#}


#function push {
#  for image in "${!path[@]}"; do
#    docker push ${REPO}/$image:${TAG}
#  done
#}


array=(
    'spark-driver::dockerfiles/driver/Dockerfile'
    'spark-executor::dockerfiles/executor/Dockerfile'
    'spark-driver-py::dockerfiles/driver-py/Dockerfile'
    'spark-executor-py::dockerfiles/executor-py/Dockerfile'
    'spark-driver-r::dockerfiles/driver-r/Dockerfile'
    'spark-executor-r::dockerfiles/executor-r/Dockerfile'
    'spark-init::dockerfiles/init-container/Dockerfile'
    'spark-shuffle::dockerfiles/shuffle-service/Dockerfile'
    'spark-resource-staging-server::dockerfiles/resource-staging-server/Dockerfile'
)

function build {
  docker build -t spark-base -f dockerfiles/spark-base/Dockerfile .
  for index in "${array[@]}"; do
    KEY="${index%%::*}"
    VALUE="${index##*::}"
    echo "$KEY - $VALUE"
    docker build -t ${REPO}/$KEY:${TAG} -f $VALUE .
  done
}

function push {
  for index in "${array[@]}"; do
    KEY="${index%%::*}"
    VALUE="${index##*::}"
    echo "$KEY - $VALUE"
    docker push ${REPO}/$KEY:${TAG}
  done
}

function usage {
  echo "Usage: ./sbin/build-push-docker-images.sh -r <repo> -t <tag> build"
  echo "       ./sbin/build-push-docker-images.sh -r <repo> -t <tag> push"
  echo "for example: ./sbin/build-push-docker-images.sh -r docker.io/kubespark -t v2.2.0 push"
}

if [[ "$@" = *--help ]] || [[ "$@" = *-h ]]; then
  usage
  exit 0
fi

while getopts r:t: option
do
 case "${option}"
 in
 r) REPO=${OPTARG};;
 t) TAG=${OPTARG};;
 esac
done

if [ -z "$REPO" ] || [ -z "$TAG" ]; then
    usage
else
  case "${@: -1}" in
    build) build;;
    push) push;;
    *) usage;;
  esac
fi
