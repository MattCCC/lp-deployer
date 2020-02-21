#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

echo ${APP_HOME};

date
info "Installing packages..."

apk add openssh \
        vim \
        ca-certificates \
        zip unzip \
        wget curl \
        git \
        npm

npm install -g yarn -s --no-progress &>/dev/null

if [[ "${BACKEND}" == "true" ]]; then
    info "Installing backend packages..."
    apk add php7 php7-fpm php7-opcache php7-json php7-iconv php7-openssl php7-phar
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

date

rm -rf /var/lib/apt/lists/*
rm /var/cache/apk/*