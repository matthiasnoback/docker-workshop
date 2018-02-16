#!/usr/bin/env bash

docker run \
    --rm \
    -d \
    --name shell \
    -it \
    alpine \
    sleep 1000000000000

docker run \
    --rm \
    --name webserver \
    -p 80:80  \
    -d \
    -v `pwd`/web:/var/www/html \
    php:7.1-apache
