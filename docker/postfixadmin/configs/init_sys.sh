#!/usr/bin/env bash
export DBUSER=${DBUSER:-"postfixuser"}
export DBPASS=${DBPASS:-"postfixpassword"}
export DBHOST=${DBHOST:-"mariadb"}
export DOMAIN=${DOMAIN:-$(hostname --domain)}

cat > /postfixadmin/config.local.php <<EOF
<?php
\$CONF['configured'] = true;
\$CONF['database_type'] = 'mysqli';
\$CONF['database_host'] = '${DBHOST}';
\$CONF['database_user'] = '${DBUSER}';
\$CONF['database_password'] = '${DBPASS}';
\$CONF['database_name'] = 'postfix';
?>
EOF
service php7.0-fpm start
service nginx start
tail -f /dev/null
