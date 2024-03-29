#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

date
info "Installing additional packages..."

# if [[ "${BACKEND}" == "true" ]]; then
    info "Installing backend packages..."
    apk add php7 php7-fpm php7-opcache php7-json php7-mbstring php7-iconv php7-openssl php7-phar php7-xml php7-simplexml php7-tokenizer php7-xmlwriter
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
# fi

date

rm -rf /var/lib/apt/lists/*
rm /var/cache/apk/*