FROM alpine:latest

ENV APP_HOME /home

VOLUME [${APP_HOME}]

WORKDIR ${APP_HOME}

RUN apk add --update --no-cache \
    bash \
    sudo \
    openssh \
    vim \
    ca-certificates \
    zip unzip \
    wget curl \
    git \
    npm

RUN npm install -g yarn -s --no-progress &>/dev/null

COPY pipe ./provision

RUN chmod +x -R ./provision; \
    ./provision/install.sh; \
    rm ./provision/install.sh

CMD ["/bin/bash"]
ENTRYPOINT ["./provision/pipe.sh"]

EXPOSE 80 443
