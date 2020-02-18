#!/usr/bin/env bash

date
echo "Installing packages..."
apk add openssh
apk add vim
apk add ca-certificates
apk add zip unzip
apk add wget curl
apk add git

apk add npm
npm install -g yarn -s --no-progress

apk add php7 php7-fpm php7-opcache php7-json php7-iconv php7-openssl php7-phar
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

rm -rf /var/lib/apt/lists/*
rm /var/cache/apk/*