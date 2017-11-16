#!/usr/bin/env bash

docker rm -f webserver
docker rm -f redis
docker network rm website
