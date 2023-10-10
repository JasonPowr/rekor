#!/bin/bash

sleep 80

echo "Deploying the rekor server!"
rekor-server -test.coverprofile=rekor-server.cov serve --trillian_log_server.address=127.0.0.1  \
                    --trillian_log_server.port=8090 --redis_server.address=127.0.0.1 --redis_server.port=6379 --rekor_server.address=0.0.0.0 \
                    --rekor_server.signer=memory --enable_attestation_storage   \
                    --attestation_storage_bucket=file:///var/run/attestations --max_request_body_size=32792576
