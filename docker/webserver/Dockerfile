FROM php:7.1-apache
#TODO remove this
RUN pecl install redis
RUN docker-php-ext-enable redis

COPY web/ /var/www/html/
