#!/bin/bash

# Hedgehog Cloud by www.eigener-server.ch https://www.eigener-server.ch/en/igel-cloud \
# is licensed under a Creative Commons Attribution 4.0 International Lizenz \
# http://creativecommons.org/licenses/by/4.0/ \
# To remove the links visit https://www.eigener-server.ch/en/igel-cloud"

set -e

if [ ! -f /firstrun ]; then

    # setup mysql
    sed -i -e "s/^datadir\s*=.*/datadir = \/host\/mariadb\/database/" /etc/mysql/my.cnf
    sed -i -e "s/\/var\/log\/mysql/\/host\/mariadb\/log/" /etc/mysql/my.cnf
    sed -i -e "s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
    sed -i -e "s/^password\s*=.*/password = ${MARIADB_ROOT_PASS}/g" /etc/mysql/debian.cnf

    # copy username / password to backup script
    sed -i -e "s/MARIADB_USER/${MARIADB_USER}/" /usr/local/bin/mysql_backup
    sed -i -e "s/MARIADB_PASS/${MARIADB_PASS}/" /usr/local/bin/mysql_backup

    # Don't run this again
    touch /firstrun
fi

if [ ! -f /host/mariadb/firstrun ]; then
    # Install Mysql
    mkdir -p /host/mariadb/log
    mkdir -p /host/mariadb/database
    chown -R mysql:mysql /host/mariadb/database
    chown -R mysql:mysql /host/mariadb/log
    /usr/bin/mysql_install_db

    # Create tables
    service mysql start
    mysql -u root -e "use mysql;update user SET PASSWORD=PASSWORD('${MARIADB_ROOT_PASS}') WHERE USER='root';flush privileges;"
    mysql -u root -p${MARIADB_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON *.* TO  'debian-sys-maint'@'localhost' identified by '${MARIADB_ROOT_PASS}' WITH GRANT OPTION;"
    mysql -u root -p${MARIADB_ROOT_PASS} -e "CREATE DATABASE IF NOT EXISTS ${MARIADB_DATABASE};"
    mysql -u root -p${MARIADB_ROOT_PASS} -e "CREATE USER '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASS}';"
    mysql -u root -p${MARIADB_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON ${MARIADB_DATABASE}.* TO '${MARIADB_USER}'@'%' WITH GRANT OPTION;"
    mysql -u root -p${MARIADB_ROOT_PASS} -e "FLUSH PRIVILEGES;"
    service mysql stop

    # Don't run this again
    touch /host/mariadb/firstrun
fi

exec "$@"
