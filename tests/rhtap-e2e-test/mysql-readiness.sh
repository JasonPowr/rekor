#!/bin/sh

# Try to connect to the MySQL database
mysql --host=127.0.0.1 --port=3306 --user=test --password=zaphod --database=test --execute="SELECT 1" > /dev/null 2>&1

# Check the exit status of the mysql command
if [ $? -eq 0 ]; then
    echo "Successfully connected to MySQL."
    exit 0
else
    echo "Failed to connect to MySQL."
    exit 1
fi
