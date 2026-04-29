# download base image Ubuntu 24.04
FROM ubuntu:24.04

# disable Promp during package installation
ARG DEBIAN_FRONTEND=noninteractive

ENV ACCEPT_EULA=Y

RUN apt-get update \
    && apt-get install -y software-properties-common --fix-missing \
    && add-apt-repository -y ppa:ondrej/php -y

RUN apt-get update \
    && apt-get install -y php8.3 php8.3-cli php8.3-dev php8.3-xml php8.3-soap php8.3-xmlrpc php8.3-mbstring php8.30-gd php8.3-pgsql php8.3-curl php8.3-zip php8.3-bcmath php8.3-redis php8.3-sqlite3 php8.3-fpm php8.3-ldap php8.3-pear libyaml-dev --fix-missing

RUN curl -sS https://getcomposer.org/installer |php
RUN mv composer.phar /usr/local/bin/composer

RUN apt-get update
RUN apt-get -y install git
RUN apt-get clean; rm -rf /var/lib/apt/list/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN apt-get update
RUN apt-get install -y wget wim htop net-tools tmux

# add cron
RUN apt-get update
RUN apt-get install -y cron

# install supervisor
RUN apt-get install -y supervisor nginx

# Timezoe
RUN apt-get update
RUN apt-get install -y --no-install-recommends tzdata \
    && rm -rf /var/lib/apt/lists/*
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Install SQL SERVER
RUN curl https://packages.microsoft.com/keys/microsft.asc | gpg --dearmor -o /usr/share/keyrings/microsft-prod.gpg && \
    curl https://packages.microsoft.com/config/ubuntu/24.04/prod.list | \
    tee /etc/apt/sources.list.d/mssql-release.lsit && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18
RUN apt-get install -y unixodbc-dev

# install sqlsrv
RUN pecl install sqlsrv
RUN pecl install pdo_sqlsrv

# install LDAP
RUN apt-get update
RUN apt-get install -y slapd ldap-utils
RUN dpkg-reconfigure slapd

# copy files
COPY openssl.cnf /etc/ssl/openssl.cnf
COPY sqlsrv.ini /etc/php/8.3/mods-available
COPY pdo_sqlsrv.ini /etc/php/8.3/mods-available
COPY custom_php.ini /etc/php/8.3/mods-available
RUN phpendmod -v 8.3 sqlsrv pdo_sqlsrv custom_php

COPY nginx.conf /etc/nginx/sites-available/default
COPY entrypoint.sh /entrypoint.sh

# LARAVEL WORKERS
COPY laravel-worker.conf /etc/supervisor/conf.d/laravel-worker.conf
COPY laravel-reverb.conf /etc/supervisor/conf.d/laravel-reverb.conf

# Alias commands
RUN echo 'alias sra="supervisorctl restart all"' >> ~/.bashrc
RUN echo 'alias srlw="supervisorctl restart laravel-worker:*"' >> ~/.bashrc
RUN echo 'alias srlwl="supervisorctl restart laravel-worker:* && tail -f /home/laravel-worker.log"' >> ~/.bashrc
RUN echo 'alias srws="supervisorctl restart laravel-reverb:*"' >> ~/.bashrc
RUN echo 'alias ssa="supervisorctl start all"' >> ~/.bashrc
RUN echo 'alias sta="supervisorctl stop all"' >> ~/.bashrc
RUN echo 'alias aoc="php artisan optimize:clear"' >> ~/.bashrc
RUN echo 'alias pam="php artisan migrate"' >> ~/.bashrc
RUN echo 'alias pams="php artisan migrate status"' >> ~/.bashrc
RUN echo 'alias pamr="php artisan migrate rollback"' >> ~/.bashrc

RUN chmod +x /entrypoint.sh
COPY 502.html /var/www/html/502.html
WORKDIR "/var/www/html"

RUN git config --global --add safe.directory /var/www/html

RUN rm "/var/www/html/index.nginx-debian.html"
RUN ["bin/bash", "-c", "echo hello all in one string"]

CMD ["entrypoint.sh"]
EXPOSE 80 443 6001