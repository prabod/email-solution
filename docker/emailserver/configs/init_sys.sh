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


#SSL CONFIGURATION

export KEY_PATH=/etc/letsencrypt/live/"$FQDN"
echo "Checking for existing certificates"

if [ ! -f "$KEY_PATH/fullchain.pem" ]; then
    echo "No Certicates Found!!"
    echo "Generating SSL Certificates with LetsEncrypt"
    letsencrypt certonly --standalone -d $HOSTNAME --noninteractive --agree-tos --email $EMAIL
    if [ ! -f "$KEY_PATH/fullchain.pem" ]; then
      echo "Certicate generation failed."
    else
      echo "Certicate generation Successfull"
    fi
fi
 cp -R ${KEY_PATH} /cert
 sed -i.bak -e "s;%DFQN%;"${HOSTNAME}";g" "/etc/postfix/main.cf"
 sed -i.bak -e "s;%DFQN%;"${HOSTNAME}";g" "/etc/dovecot/conf.d/10-ssl.conf"

 find /etc/postfix/sql/ -name "mysql_virtual*" -exec sed -i -e "s;postfixuser;"${DBUSER}";g" {} \;
 find /etc/postfix/sql/ -name "mysql_virtual*" -exec sed -i -e "s;postfixpassword;"${DBPASS}";g" {} \;
 find /etc/postfix/sql/ -name "mysql_virtual*" -exec sed -i -e "s;127.0.0.1;"${DBHOST}";g" {} \;
 sed -i -e "s;redis;"${REDIS_HOST}";g" "/etc/rspamd/local.d/redis.conf"
 sed -i -e "s;redis;"${REDIS_HOST}";g" "/etc/rspamd/local.d/redis.conf"

 sed -i -e "s;mailuser;"${DBUSER}";g" "/etc/dovecot/dovecot-sql.conf.ext"
 sed -i -e "s;mailuserpass;"${DBPASS}";g" "/etc/dovecot/dovecot-sql.conf.ext"
 sed -i -e "s;127.0.0.1;"${DBHOST}";g" "/etc/dovecot/dovecot-sql.conf.ext"

 PASSWORD=$(rspamadm pw --quiet --encrypt --type pbkdf2 --password "${RSPAMD_PASSWORD}")
 sed -i "s;pwrd;"${PASSWORD}";g" "/etc/rspamd/local.d/worker-controller.inc"

 service postfix restart
 service dovecot restart
 systemctl start rspamd
 cat
