# Run the `hello-world` image

How to display info about stopped containers:

```bash
docker ps -a
```

# Run a small Linux distribution

Let's start an interactive shell (`sh`):

```bash
docker run alpine sh
```

How to run the `sh` command interactively:

```bash
docker run -it alpine sh
```

- Which user does the shell command run under? `root`
- Where are all the other processes that run on your machine? _They are invisible inside the container._ 

# Run a web server

We'll start an Apache web server:

```bash
docker run php:7.1-apache
```

How you can publish container port 80 as port 80 on localhost (using `-p`):

```bash
docker run -p 80:80 php:7.1-apache
```

# Serve PHP files; mount a directory from the host

To mount a directory from the host (using `-v`):

```bash
docker run -v `pwd`/web:/var/www/html -p 80:80 php:7.1-apache
```

# Managing running containers

How you can run a container in the background (using `-d`)

```bash
docker run -d -v `pwd`/web:/var/www/html -p 80:80 php:7.1-apache
```

Provide a memorable name for the container, like `webserver`:

```bash
docker run --name webserver -d -v `pwd`/web:/var/www/html -p 80:80 php:7.1-apache
```

To let automatically remove a container after it has stopped, you could simply add the `--rm` flag:

```bash
docker run --rm --name webserver -d -v `pwd`/web:/var/www/html -p 80:80 php:7.1-apache
```

# Implementing a visitor counter

The `Dockerfile` should look like this:

```docker
FROM php:7.1-apache
RUN pecl install redis
RUN docker-php-ext-enable redis
```

# Bash wrapper scripts

An example of `up.sh`:

```bash
#!/usr/bin/env bash

set -e

docker build -t my_webserver -f docker/webserver/Dockerfile ./

docker pull redis:3.2

docker run -d --name redis redis:3.2

docker run -p 80:80 -v `pwd`/web:/var/www/html -d --link redis --name webserver my_webserver
```

An example of `down.sh`:

```bash
#!/usr/bin/env bash

set -e

docker rm -f webserver
docker rm -f redis
```

# Networks

An example of `up.sh`:

```bash
#!/usr/bin/env bash

set -e

docker build -t my_webserver -f docker/webserver/Dockerfile ./

docker pull redis:3.2

docker network create website || true

docker run -d --name redis --network website redis:3.2

docker run -p 80:80 -v `pwd`/web:/var/www/html -d --network website --name webserver my_webserver
```

An example of `down.sh`:

```bash
#!/usr/bin/env bash

set -e

docker rm -f webserver
docker rm -f redis
docker network rm website
```

# Use your own hosted registry


An example of `up.sh`, which uses a self-hosted registry (don't forget to replace "matthiasnoback" with your own name). This example also shows how to use variables in Bash scripts:

```bash
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
```
