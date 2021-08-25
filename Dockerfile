# FROM haproxy:2.4
FROM haproxytech/haproxy-ubuntu:2.4

USER root
RUN mkdir --mode 775 /var/run/haproxy && \
	chown haproxy:haproxy /var/run/haproxy /etc/haproxy

RUN apt-get update && \
	apt install -y procps netcat-openbsd net-tools

USER haproxy