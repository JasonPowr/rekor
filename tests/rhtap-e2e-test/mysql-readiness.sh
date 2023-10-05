#!/bin/bash

# MySQL login details
HOST="localhost"
USER="test"
PASSWORD="zaphod"

count=0
echo -n "Waiting for MySQL to start"

until mysqladmin ping -h"$HOST" -u"$USER" -p"$PASSWORD" --silent; do
    if [ $count -eq 16 ]; then
       echo "! timeout reached"
       exit 1
    else
       echo -n "."
       sleep 10
       ((count++))
    fi
done

echo "MySQL is up!"
