FROM php:7.3-fpm-alpine

ENV APP_HOME /home

VOLUME [${APP_HOME}]

WORKDIR ${APP_HOME}

RUN apk add --update --no-cache \
    bash make \
    sudo \
    openssh \
    vim \
    ca-certificates \
    zip unzip \
    wget curl \
    git \
    npm

RUN npm install -g yarn -s --no-progress &>/dev/null

# fix work iconv library with alphine
# RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv
# ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# RUN apk add php7 php7-fpm php7-opcache php7-json php7-mbstring php7-iconv php7-openssl php7-phar php7-xml php7-simplexml php7-tokenizer php7-xmlwriter
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY pipe ./provision

RUN chmod +x -R ./provision
    #; \
    # ./provision/install.sh; \
    # rm ./provision/install.sh

CMD ["/bin/bash"]
ENTRYPOINT ["./provision/pipe.sh"]

EXPOSE 80 443
