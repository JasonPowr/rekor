#!/bin/bash

# MySQL container details
HOST="localhost"
PORT="3306"
USER="root"
PASSWORD="zaphod"

# Maximum number of attempts to ping the server
MAX_ATTEMPTS=30
COUNT=0

# Ping the server until it's ready or the maximum number of attempts is reached
while ! mysqladmin ping -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --silent; do
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $MAX_ATTEMPTS ]; then
        echo "Server is not responding after $MAX_ATTEMPTS attempts. Exiting."
        exit 1
    fi
    echo "Waiting for server to be ready..."
    sleep 5
done

echo "Server is ready!"
