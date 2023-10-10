#!/bin/bash

sleep 60

echo "Deploying trillian log server!"
/bin/trillian_log_server --storage_system=mysql --mysql_uri="test:zaphod@tcp(127.0.0.1:3306)/test" --rpc_endpoint=0.0.0.0:8090 --http_endpoint=0.0.0.0:8091 --alsologtostderr
