From ubuntu:16.04
MAINTAINER Prabod Rathnayaka <prabod@rathnayaka.me>
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y purge exim4*
RUN apt-get -y install letsencrypt
RUN apt-get -y install postfix postfix-mysql
RUN apt-get -y install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql dovecot-sieve

RUN apt-get -y install gnupg python-gpgme sudo
RUN adduser --system --no-create-home --disabled-login zeyple
RUN mkdir -p /etc/zeyple/keys && chmod 700 /etc/zeyple/keys && chown zeyple: /etc/zeyple/keys
ADD https://raw.github.com/infertux/zeyple/master/zeyple/zeyple.py /usr/local/bin/zeyple.py
RUN chmod 744 /usr/local/bin/zeyple.py && chown zeyple: /usr/local/bin/zeyple.py
ADD https://raw.github.com/infertux/zeyple/master/zeyple/zeyple.conf.example /etc/zeyple/zeyple.conf
RUN touch /var/log/zeyple.log && chown zeyple: /var/log/zeyple.log

COPY ./emailserver/configs/Postfix /etc/postfix/
COPY ./emailserver/configs/Dovecot /etc/dovecot/
RUN groupadd -g 5000 vmail && useradd -g vmail -u 5000 vmail -d /var/mail
RUN chown -R vmail:vmail /var/mail
RUN chmod -R o-rwx /etc/postfix
RUN chown -R vmail:dovecot /etc/dovecot
RUN chmod -R o-rwx /etc/dovecot

COPY ./emailserver/configs/rspamd.sh /
RUN ./rspamd.sh
COPY ./emailserver/configs/Rspamd /etc/rspamd/
RUN mkdir /var/lib/rspamd/dkim/
RUN rspamadm dkim_keygen -b 2048 -s 2018 -k /var/lib/rspamd/dkim/2018.key > /var/lib/rspamd/dkim/2018.txt
RUN chown -R _rspamd:_rspamd /var/lib/rspamd/dkim
RUN chmod 440 /var/lib/rspamd/dkim/*
RUN cp -R /etc/rspamd/local.d/dkim_signing.conf /etc/rspamd/local.d/arc.conf
COPY ./emailserver/configs/init_sys.sh /bin/
RUN chmod +x /bin/init_sys.sh
