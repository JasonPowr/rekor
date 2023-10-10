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
while ! nc -z "$HOST" "$PORT"; do
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $MAX_ATTEMPTS ]; then
        echo "Server is not responding after $MAX_ATTEMPTS attempts. Exiting."
        exit 1
    fi
    echo "Waiting for server to be ready..."
    sleep 5
done

echo "Server is ready!"

echo "Deploying the rekor server!"
/bin/rekor-server -test.coverprofile=rekor-server.cov serve --trillian_log_server.address=127.0.0.1  \
                    --trillian_log_server.port=8090 --redis_server.address=127.0.0.1 --redis_server.port=6379 --rekor_server.address=0.0.0.0 \
                    --rekor_server.signer=memory --enable_attestation_storage   \
                    --attestation_storage_bucket=file:///var/run/attestations --max_request_body_size=32792576
