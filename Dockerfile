FROM alpine

ENV APP_HOME /home

VOLUME [${APP_HOME}]

WORKDIR ${APP_HOME}

RUN apk add --update --no-cache \
    bash \
    sudo

COPY pipe ./provision

RUN chmod +x -R ./provision; \
    ./provision/install.sh

CMD ["/bin/bash"]
ENTRYPOINT ["./provision/pipe.sh"]