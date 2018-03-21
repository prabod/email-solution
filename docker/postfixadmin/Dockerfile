From ubuntu:16.04
MAINTAINER Prabod Rathnayaka <prabod@rathnayaka.me>
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install php7.0 php7.0-fpm php7.0-mysql nginx -y
ADD https://github.com/postfixadmin/postfixadmin/archive/postfixadmin-3.1.tar.gz /
WORKDIR /
RUN tar -xzf *.tar.gz && mv postfixadmin-postfixadmin-3.1 postfixadmin
COPY ./postfixadmin/configs/default /etc/nginx/sites-available/
COPY ./postfixadmin/configs/init_sys.sh /bin/
RUN chmod +x /bin/init_sys.sh

