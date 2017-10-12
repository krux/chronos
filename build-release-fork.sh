#!/bin/sh
set -e

branch=`git rev-parse --abbrev-ref HEAD`
if [ "$branch" = "master" ]; then
  set +e # ignore error of following command
  tag=`git describe --exact-match --tags HEAD`
  exit_code=$?
  set -e
  if [ $exit_code = 0 ]; then
    image_tag=`git describe --tags`
  else
    image_tag="latest"
  fi
else
  image_tag=$branch
fi
#version=`git describe --tags`

version=$( grep -Po '<version>\K[^<]*' ./pom.xml | head -1 | sed -e 's/-.*//' )

echo "Branch: $branch"
echo "Tag: $tag"
echo "Image tag: $image_tag"
echo "Version: $version"

mkdir -p tmp

# build jar
docker run --rm -e http_proxy=$http_proxy -v `pwd`:/mnt/build --entrypoint=/bin/sh maven:3-jdk-8 -c "\
  curl -sL https://deb.nodesource.com/setup_7.x | bash - \
  && apt-get update && apt-get install -y --no-install-recommends nodejs apt-transport-https build-essential \
  && ln -sf /usr/bin/nodejs /usr/bin/node \
  && nodejs --version \
  && npm --version \
  && cp -r /mnt/build /chronos \
  && cd /chronos \
  && mvn --version \
  && mvn clean \
  && mvn package \
  && ls -al /chronos \
  && ls -al /chronos/target/ \
  && cp target/chronos-$version.jar /mnt/build/tmp/chronos.jar \
  "

# build image DISABLED
#docker build --build-arg http_proxy=$http_proxy -t mesosphere/chronos:$image_tag .

#if [ ! -z ${DOCKER_HUB_USERNAME+x} -a ! -z ${DOCKER_HUB_PASSWORD+x} ]; then
  # login to dockerhub
#  docker login -u "${DOCKER_HUB_USERNAME}" -p "${DOCKER_HUB_PASSWORD}"

  # push image
#  docker push mesosphere/chronos:$image_tag
#fi
