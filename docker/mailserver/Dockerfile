
From ubuntu:16.04
MAINTAINER Prabod Rathnayaka <prabod@rathnayaka.me>
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y purge exim4*
RUN apt-get -y install letsencrypt
RUN apt-get -y install postfix postfix-mysql
RUN apt-get -y install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql dovecot-sieve
ENV DOMAIN example.com
RUN echo $DOMAIN
ENV EMAIL prabod@rathnayaka.me
#RUN letsencrypt certonly --standalone -d $DOMAIN --noninteractive --agree-tos --email $EMAIL
RUN apt-get -y install gnupg python-gpgme sudo
RUN adduser --system --no-create-home --disabled-login zeyple
RUN mkdir -p /var/lib/zeyple/keys && chmod 700 /var/lib/zeyple/keys && chown zeyple: /var/lib/zeyple/keys
RUN cp zeyple.conf.example /etc/zeyple.conf
RUN cp zeyple.py /usr/local/bin/zeyple.py
RUN chmod 744 /usr/local/bin/zeyple.py && chown zeyple: /usr/local/bin/zeyple.py
RUN touch /var/log/zeyple.log && chown zeyple: /var/log/zeyple.log

COPY ./configs/Postfix /etc/postfix/
COPY ./configs/Dovecot /etc/dovecot/
RUN mkdir -p /var/mail/vhosts/example.com
RUN groupadd -g 5000 vmail && useradd -g vmail -u 5000 vmail -d /var/mail
RUN chown -R vmail:vmail /var/mail
RUN chmod -R o-rwx /etc/postfix
RUN chown -R vmail:dovecot /etc/dovecot
RUN chmod -R o-rwx /etc/dovecot

RUN service postfix restart
RUN service dovecot restart
