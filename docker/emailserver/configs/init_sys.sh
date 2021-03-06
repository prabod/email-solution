#!/usr/bin/env bash

export EMAIL
export KEY_PATH

export FQDN=${FQDN:-$(hostname --fqdn)}
export DOMAIN=${DOMAIN:-$(hostname --domain)}
export REDIS_HOST=${REDIS_HOST:-"redis"}
export REDIS_PORT=${REDIS_PORT:-6379}
export DBUSER=${DBUSER:-"postfixuser"}
export DBPASS=${DBPASS:-"postfixpassword"}
export DBHOST=${DBHOST:-"mariadb"}
export RSPAMD_PASSWORD=${RSPAMD_PASSWORD:-"password"}


if [ -z "$EMAIL" ]; then
  echo "[ERROR] Email Must be set !"
  exit 1
fi

if [ -z "$DBPASS" ]; then
  echo "[ERROR] MariaDB database password must be set !"
  exit 1
fi

if [ -z "$RSPAMD_PASSWORD" ]; then
  echo "[ERROR] Rspamd password must be set !"
  exit 1
fi

if [ -z "$FQDN" ]; then
  echo "[ERROR] The fully qualified domain name must be set !"
  exit 1
fi

if [ -z "$DOMAIN" ]; then
  echo "[ERROR] The domain name must be set !"
  exit 1
fi

# https://github.com/docker-library/redis/issues/53
if [[ "$REDIS_PORT" =~ [^[:digit:]] ]]
then
  REDIS_PORT=6379
fi

echo $HOSTNAME $DOMAIN $EMAIL

mkdir -p /var/mail/vhosts/$DOMAIN

chown -R vmail /var/mail
#SSL CONFIGURATION
chmod -R 755 /etc/letsencrypt/
export KEY_PATH=/etc/letsencrypt/live/"$HOSTNAME"/
files=$(shopt -s nullglob dotglob; echo $KEY_PATH)
echo $KEY_PATH
echo "Checking for existing certificates"


if ["$DEBUG" = true]; then
  mkdir $KEY_PATH
  openssl req -nodes -x509 -newkey rsa:4096 -keyout ${KEY_PATH}.privkey.pem -out ${KEY_PATH}.fullchain.pem -days 365 -subj "/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=www.example.com"
  echo "IN DEBUG MODE!!!! - GENERATED SELF SIGNED SSL KEY"
else
  if (( ${#files} )); then
      echo "Found existing keys!!"
  else
      echo "No Certicates Found!!"
      echo "Generating SSL Certificates with LetsEncrypt"
      letsencrypt certonly --standalone -d $HOSTNAME --noninteractive --agree-tos --email $EMAIL
      if (( ${#files} )); then
        echo "Certicate generation Successfull"
      else
        echo "Certicate generation failed."
        exit 1
      fi
  fi
fi
 cp -R /etc/letsencrypt/ /cert
 sed -i.bak -e "s;%DFQN%;"${HOSTNAME}";g" "/etc/postfix/main.cf"
 sed -i.bak -e "s;%DOMAIN%;"${DOMAIN}";g" "/etc/postfix/main.cf"
 sed -i.bak -e "s;%DOMAIN%;"${DOMAIN}";g" "/etc/dovecot/conf.d/15-lda.conf"
 sed -i.bak -e "s;%DOMAIN%;"${DOMAIN}";g" "/etc/dovecot/conf.d/20-lmtp.conf"
 sed -i.bak -e "s;%DFQN%;"${HOSTNAME}";g" "/etc/dovecot/conf.d/10-ssl.conf"

 find /etc/postfix/sql/ -name "mysql_virtual*" -exec sed -i -e "s;postfixuser;"${DBUSER}";g" {} \;
 find /etc/postfix/sql/ -name "mysql_virtual*" -exec sed -i -e "s;postfixpassword;"${DBPASS}";g" {} \;
 find /etc/postfix/sql/ -name "mysql_virtual*" -exec sed -i -e "s;127.0.0.1;"${DBHOST}";g" {} \;
 sed -i -e "s;redis;"${REDIS_HOST}";g" "/etc/rspamd/local.d/redis.conf"
 sed -i -e "s;redis;"${REDIS_HOST}";g" "/etc/rspamd/local.d/redis.conf"

 sed -i -e "s;postfixuser;"${DBUSER}";g" "/etc/dovecot/dovecot-sql.conf"
 sed -i -e "s;postfixpassword;"${DBPASS}";g" "/etc/dovecot/dovecot-sql.conf"
 sed -i -e "s;127.0.0.1;"${DBHOST}";g" "/etc/dovecot/dovecot-sql.conf"

 PASSWORD=$(rspamadm pw --quiet --encrypt --type pbkdf2 --password "${RSPAMD_PASSWORD}")
 sed -i "s;pwrd;"${PASSWORD}";g" "/etc/rspamd/local.d/worker-controller.inc"
 
 groupadd -g 5000 vmail && useradd -g vmail -u 5000 vmail -d /var/mail
 chown -R vmail:vmail /var/mail
 mkdir -p /var/mail/sieve/global
 cp -R /sieve/* /var/mail/sieve/global/
 sievec /var/mail/sieve/global/spam-global.sieve
 sievec /var/mail/sieve/global/report-ham.sieve
 rspamadm dkim_keygen -b 1024 -s 2018 -d ${DOMAIN} -k /var/lib/rspamd/dkim/2018.key > /var/lib/rspamd/dkim/2018.txt
 chown -R _rspamd:_rspamd /var/lib/rspamd/dkim
 chmod 440 /var/lib/rspamd/dkim/*
 sudo chown -R vmail: /var/mail/sieve/
 cat /var/lib/rspamd/dkim/2018.txt
 touch /var/log/mail.log
 touch /var/log/mail.err
 chown root:root /etc/postfix/dynamicmaps.cf
 sudo chown root:root /etc/postfix/main.cf
 sudo chmod 0644 /etc/postfix/main.cf
 chgrp postfix /etc/postfix/sql/mysql_virtual_*.cf
 chmod u=rw,g=r,o= /etc/postfix/sql/mysql_virtual_*.cf
 sudo chmod a+w /var/log/mail*
 sudo chown zeyple /etc/zeyple.conf
 touch /etc/postfix/virtual
 touch /etc/postfix/access
 postmap hash:/etc/postfix/virtual
 postmap hash:/etc/postfix/access

 service rsyslog start
 service postfix start
 service dovecot restart
 service rspamd start
 tail -f /dev/null
