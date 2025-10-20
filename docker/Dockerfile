# FROM debian:12
FROM ubuntu:22.04

COPY ./bin /apps/snpp/bin
COPY ./framework /apps/snpp/framework
COPY ./start_server.sh /apps/snpp/start_server.sh
RUN chmod +x /apps/snpp/start_server.sh
COPY ./stop_server.sh /apps/snpp/stop_server.sh
RUN chmod +x /apps/snpp/stop_server.sh

RUN mkdir /apps/snpp/app
WORKDIR /apps/snpp/app

RUN apt-get update && \
    apt-get install -y curl wget vim net-tools iputils-ping netcat-openbsd procps && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/apps/snpp/app", "/apps/snpp/framework", "/apps/snpp/app/logs"]

ENTRYPOINT ["/bin/bash", "/apps/snpp/start_server.sh"]

EXPOSE 8888 8000 2013 2526
