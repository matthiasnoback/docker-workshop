#!/usr/bin/env bash

set -eu

docker run -d -p 5000:5000 --restart=always --name registry registry:2 || true
registry_host="localhost:5000"

my_webserver_tag="${registry_host}/matthiasnoback/my_webserver"
docker build -t "${my_webserver_tag}" -f docker/webserver/Dockerfile ./
docker push "${my_webserver_tag}"

docker pull redis:3.2
my_redis_tag="${registry_host}/my_redis"
docker tag redis:3.2 "${my_redis_tag}"
docker push "${my_redis_tag}"

docker network create website || true

docker run \
    -d \
    --name redis \
    --network website \
    "${my_redis_tag}"

docker run \
    -p 80:80 \
    -v `pwd`/web:/var/www/html \
    -d \
    --network website \
    --name webserver \
    "${my_webserver_tag}"
