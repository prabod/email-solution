From debian:stretch-slim
MAINTAINER Prabod Rathnayaka <prabod@rathnayaka.me>
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y purge exim4*
RUN apt-get -y install letsencrypt openssl
RUN apt-get -y install postfix postfix-mysql postfix-pcre libsasl2-modules
RUN apt-get install -y rsyslog fetchmail libdbi-perl libdbd-pg-perl libdbd-mysql-perl liblockfile-simple-perl
RUN apt-get -y install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql dovecot-sieve dnsutils

RUN apt-get -y install gnupg python-gpgme dovecot-managesieved sudo
RUN adduser --system --no-create-home --group --home /etc/zeyple --disabled-login zeyple
RUN mkdir -p /etc/zeyple/keys && chmod 700 /etc/zeyple/keys && chown zeyple: /etc/zeyple/keys
ADD https://raw.github.com/infertux/zeyple/master/zeyple/zeyple.py /usr/local/bin/zeyple.py
RUN chmod 744 /usr/local/bin/zeyple.py && chown zeyple: /usr/local/bin/zeyple.py
ADD https://raw.github.com/infertux/zeyple/master/zeyple/zeyple.conf.example /etc/zeyple.conf
RUN touch /var/log/zeyple.log && chown zeyple: /var/log/zeyple.log
RUN chown -R zeyple /etc/zeyple /usr/local/bin/zeyple.py


COPY ./emailserver/configs/Postfix /etc/postfix/
COPY ./emailserver/configs/Dovecot /etc/dovecot/
RUN groupadd -g 5000 vmail && useradd -g vmail -u 5000 vmail -d /var/mail
RUN chown -R vmail:vmail /var/mail
RUN chown -R postfix /etc/postfix
RUN chmod -R o-rwx /etc/postfix
RUN chmod -R 755 /etc/postfix
RUN chown -R vmail:dovecot /etc/dovecot
RUN chmod -R o-rwx /etc/dovecot

COPY ./emailserver/configs/rspamd.sh /
RUN ./rspamd.sh
COPY ./emailserver/configs/Rspamd /etc/rspamd/
RUN mkdir /var/lib/rspamd/dkim/
RUN cp -R /etc/rspamd/local.d/dkim_signing.conf /etc/rspamd/local.d/arc.conf
COPY ./emailserver/configs/sieve /sieve

COPY ./emailserver/configs/init_sys.sh /bin/
RUN chmod +x /bin/init_sys.sh
