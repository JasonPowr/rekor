#!/bin/bash

sleep 100

echo "Deploying trillian log signer!"
/bin/trillian_log_signer --storage_system=mysql --mysql_uri="test:zaphod@tcp(127.0.0.1:3306)/test" --rpc_endpoint=0.0.0.0:8090 --http_endpoint=0.0.0.0:8091 --force_master --alsologtostderr