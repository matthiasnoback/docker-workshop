# Run the `hello-world` image

On your terminal, run:

```bash
docker run hello-world
```

Read what it tells you about the process of running this container.

Now run `docker ps` to find out if the container is still running. `hello-world` is nowhere to be found... Find out how to display info about stopped containers in the [documentation for `docker ps`](https://docs.docker.com/engine/reference/commandline/ps/).

# Run a small Linux distribution

The official [`alpine` image](https://hub.docker.com/_/alpine/) contains a small Linux distribution. It is often used to keep distributed images small.

Try running it:

```bash
docker run alpine
```

It doesn't do anything by default. In fact, you have to provide a command. Take a look at the documentation for [`docker run`](https://docs.docker.com/engine/reference/commandline/run/) to find out how you can provide a command. For instance, let's start an interactive shell (`sh`).
 
It still doesn't do anything because it needs:

- a terminal (TTY)
- user input (via STDIN)

Take another look at the documentation for [`docker run`](https://docs.docker.com/engine/reference/commandline/run/) to find out how to run the `sh` command interactively.

If you have succeeded you should see a shell prompt:

```
/ #
```

You should be able to type in a command, like `ls`.

Now try `ps aux`. 

- Which user does the shell command run under?
- Where are all the other processes that run on your machine?

# Run a web server

We'll start an Apache web server.

We use the [official `php` image](https://hub.docker.com/_/php/) for it. Pick one that includes Apache. You can run a specific version of an image by adding a tag to the name of the image, for example `php:7.1-apache`.

Try running the image. It will start up the web server that listens at port 80. However, currently we can't reach it. Press `Ctrl + C` to stop the container. 
 
Look up in the [documentation for `docker run`](https://docs.docker.com/engine/reference/commandline/run/) how you can publish container port 80 as port 80 on localhost. When you've figured it out, take a look at `http://localhost/`. It should show something like this:

```
Forbidden

You don't have permission to access / on this server.
Apache/2.4.10 (Debian) Server at localhost Port 80
```

At least it responds!

# Serve PHP files; mount a directory from the host

We'd like to serve the `index.php` file in the `web/` directory.

How to get it inside the container so Apache can find it?

We could simply mount the root directory of the project into the container at the right location, which is `/var/www/html/`.

To mount a directory from the host, we should provide its full path, e.g. `/Users/matthias/Projects/matthiasnoback/docker-workshop/web`, then a colon (`:`), and finally the "target" directory inside the container, e.g. `/var/www/html/`. On Unix systems we can use `pwd` to get the working directory, so we can simply run:

```bash
docker run -v `pwd`/web:/var/www/html ...
```

If we provide the remaining arguments (the port to publish and the image name), we should be able to reload `http://localhost/` and see the following:

```
Hello World!
```

As you may have noticed, this should have been "Hello, World!". Make the change in `web/index.php` and reload the page.

# Managing running containers

It wouldn't be very handy if you'd have to leave open your terminal while the web server was running. Take a look at the [documentation for `docker run`](https://docs.docker.com/engine/reference/commandline/run/) how you can run a container in the background.

Once you have the web server running in the background, you can run `docker ps` again to take a closer look. You can find out a lot more about the container by copying the container ID of the web server and feed it as an argument to `docker inspect`.

At some point you want to stop the web server. You can do so by running `docker stop [container ID]`. However, that means you'll have to look up the container ID first, using `docker ps`. Instead, you could provide a memorable name for the container, like `webserver`:

```bash
docker run --name webserver ...
```

If you do so, you can then stop the container by its name, e.g.

```bash
docker stop webserver
```

Stopped containers aren't automatically removed, so you can restart them if you like:

```bash
docker restart webserver
```

If you want to run the `webserver` container again, with different options and arguments, you first have to remove it:

```bash
docker rm webserver
```

Add `-f` if the container is still running (or stop it first).

To let automatically remove a container after it has stopped, you could simply add the `--rm` flag to the `docker run` command. 

## Logging

Containers usually log interesting information to `stdout` and `stderr`. You saw some of this already when you ran `docker run`. But if you run containers in the background, you have to explicitly look up the logs, like this:

```bash
docker logs webserver
```

Add `-f` if you want to "follow" the logs (like with `tail -f`).

# Building a custom image

Instead of using a "bind-mount volume" to make files from the host available inside the container, we can also copy the files into the container. Take a look at how this build step is defined in `docker/webserver/Dockerfile`.

You can build the container by running:

```bash
docker build -t my_webserver -f docker/webserver/Dockerfile ./
```

This means: tag the image as `my_webserver`, use `docker/webserver/Dockerfile` for build instructions and use the current working directory `./` as the "build context". This means that you can refer to any project file within the given `Dockerfile`.

Now you can start the web server again, this time referring to your own image:

```bash
docker run -p 80:80 my_webserver
```

Note that we haven't provided the volume anymore. We don't need it, since `index.php` has been copied to the right location already. The image is completely stand-alone and could be deployed to a production server if we like.

There are lots of other things you can do in a `Dockerfile`. Take a look at the [reference documentation](https://docs.docker.com/engine/reference/builder/).

# Implementing a visitor counter

An application often needs something else to function correctly. For example, if we'd like our website to have a visitor counter, we need to store the current visit count somewhere. An easy choice would be to use a key-value store, like [Redis](https://redis.io/) to store this number.

There is an [official image for Redis](https://hub.docker.com/_/redis/) too.

Let's start it:

```bash
docker run --name redis -d redis:3.2
```

We add the `-d` flag to make Redis start in the background (we don't need to provide interactive input, or read its output right now).

To be able to use it in a PHP application, we can install the [`redis` PECL extension](https://github.com/phpredis/phpredis). Add the following lines to `docker/webserver/Dockerfile` to install this extension in the `webserver` image. The best place for these lines is *right after the line starting with `FROM`*:

```docker
RUN pecl install redis
RUN docker-php-ext-enable redis
```

Also, uncomment the lines in `web/index.php` which make the actual connection to Redis.

Then rebuild the image:

```bash
docker build -t my_webserver -f docker/webserver/Dockerfile ./
```

You should see the `redis` extension being installed in the container image.

To be able to connect to the `redis` container using its host name, we should *link* the the `redis` container to the `webserver` container, using the `--link` option:

```bash
docker run \
    -p 80:80 \
    -v `pwd`/web:/var/www/html \
    -d \
    --link redis \
    --name webserver \
    my_webserver
```

# Bash wrapper scripts

Nice, all those `docker` commands. Really powerful too. But we don't want to keep them all in our head. Create a Bash script called `up.sh` that simply contains all the commands for:

- building the image for the web server
- pulling the image for redis (`docker pull redis:3.2`)
- starting the redis service
- starting the web server

Create another Bash script that contains all the commands for:

- stopping the web server
- stopping the redis service
- removing the web server container
- removing the redis service container

Learn more about Bash from the article [Bash scripting quirks & safety tips](https://jvns.ca/blog/2017/03/26/bash-quirks/) by Julia Evans.

The [BASH Programming](http://tldp.org/HOWTO/Bash-Prog-Intro-HOWTO.html) website contains lots of interesting material too.

## Hints

- Start the scripts as follows:

    ```bash
    #!/usr/bin/env bash
    ```
    
- Make the scripts executable. For example: run `chmod u+x ./up.sh` so you can execute it as `./up.sh`
- To make a script fail as soon as any command fails, add: 

    ```bash
    set -e
    ```

By the way, in another workshop we'll take a look at [Docker Compose](https://docs.docker.com/compose/), which can do a lot of this kind of wrapping for us.

# Networks

Instead of linking containers explicitly using `--link` you could make them part of a sub-network, to which only connected containers have access. First, create a new network called "website" (you can add this line to `up.sh`, before the `docker run` commands):

```bash
docker network create website
```

You can add both containers to the same network by providing an extra option: `--network=website`. Update the `up.sh` script to do so.

To test it all, first run `down.sh`, then `up.sh` again and visit `http://localhost/` again.

## Hints

- The second time you run `docker network create website`, the command will fail, and so will the entire script. To prevent this from happening add ` || true` to the line. This will make the command always succeed.
- For symmetry, at the end of `down.sh` you could `docker network rm website`.

# Share your image with the world

In order to deploy a container image, you should push it to an image registry first. Though you can easily [host one yourself](https://hub.docker.com/_/registry/), let's use the free (but public) Docker Hub image registry for now.
 
First, create an account on [hub.docker.com](https://hub.docker.com). Then, login using [`docker login`](https://docs.docker.com/engine/reference/commandline/login/).

Now, you need to re-build (or [re-tag](https://docs.docker.com/engine/reference/commandline/tag/)) your image and provide a more elaborate tag:

```bash
docker build -t matthiasnoback/my_webserver -f docker/webserver/Dockerfile ./
```

(Where `matthiasnoback` should be replaced with your own Docker Hub username of course.)

Now you can run:

```bash
docker push matthiasnoback/my_webserver
```

By the way, you can be more specific and supply a version number of some sorts, e.g. `matthiasnoback/my_webserver:1.0.0`.

Take a look at your Docker Hub dashboard to find out if the image was pushed successfully.

Now that it is available, you can pull it from the registry too.

First, remove existing copies of your image:

```bash
docker rmi matthiasnoback/my_webserver
```

Now, pull the latest image from Docker Hub:

```bash
docker pull matthiasnoback/my_webserver
```

The image will be downloaded and you can start using it again to run a container based on it.

# Use your own hosted registry

Instead of pushing images to Docker Hub, you could also host your own image registry. First, run:

```bash
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

The registry is still empty at this point. If you want to push images to it, you need to tag them first, e.g.:

```bash
docker tag matthiasnoback/my_webserver localhost:5000/matthiasnoback/my_webserver
docker push localhost:5000/matthiasnoback/my_webserver
```

You'll find that you won't be able to push images to your "insecure" registry. You can configure which registries are allowed by clicking on the Docker Whale icon, going to `Preferences`, `Daemon` and adding `localhost:5000` as an insecure registry. After applying and restarting, you should be able to push the image after all. For Linux you might have to [restart the Docker daemon with an extra flag](https://docs.docker.com/engine/reference/commandline/dockerd/), or modify the Daemon's configuration file.

You can also push official images you've previously pulled to your local registry:

```bash
docker tag redis localhost:5000/redis
docker push localhost:5000/redis
```

Use the registry's HTTP API to find out which repositories and tags are currently known to it. You'll find the available endpoints listed in the documentation of the [HTTP API V2](https://docs.docker.com/registry/spec/api/). E.g. open `http://localhost:5000/v2/_catalog` in your browser. 

From now on you can pull and run images from the self-hosted registry. Don't forget to add the location of the registry (i.e. `localhost:5000`):

```bash
docker run -d --name redis localhost:5000/redis
``` 
