FROM debian:12

COPY framework /apps/snpp/framework
COPY docker/start_server.sh /apps/snpp/start_server.sh
COPY docker/stop_server.sh /apps/snpp/stop_server.sh

RUN apt-get update && \
    apt-get install -y curl wget vim net-tools iputils-ping netcat-openbsd telnet && \
    rm -rf /var/lib/apt/lists/*

VOLUME ["/apps/snpp/app", "/apps/snpp/app/logs"]

WORKDIR /apps/snpp/app

RUN chmod +x /apps/snpp/start_server.sh
RUN chmod +x /apps/snpp/stop_server.sh

ENTRYPOINT ["/bin/bash", "/apps/snpp/start_server.sh"]

EXPOSE 8888 8000 2013 2526
