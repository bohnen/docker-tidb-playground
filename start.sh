#!/bin/bash

# Start tiup playground in background
if [ -n "$UNISTORE" ]; then
    /root/.tiup/components/tidb/$TIDB_VERSION/tidb-server &
else
    tiup playground --host "0.0.0.0" --db 1 --pd 1 --kv 1 --tiflash 0 --without-monitor &
fi

# Wait for TiDB to be ready (max 30 seconds)
echo "Waiting for TiDB to start..."
timeout=120
elapsed=0

while [ $elapsed -lt $timeout ]; do
    if curl -s -o /dev/null -w "%{http_code}" localhost:10080 | grep -q "200"; then
        echo "TiDB is ready!"
        break
    fi
    
    sleep 1
    elapsed=$((elapsed + 1))
    echo "Waiting... ($elapsed/$timeout)"
done

if [ $elapsed -eq $timeout ]; then
    echo "Timeout: TiDB failed to start within $timeout seconds"
fi

# Check for SQL files and execute them
if [ -d "/sql" ] && [ "$(ls -A /sql/*.sql 2>/dev/null)" ]; then
    echo "Found SQL files in /sql directory"
    
    # Execute SQL files in alphabetical order
    for sql_file in /sql/*.sql; do
        if [ -f "$sql_file" ]; then
            echo "Executing: $sql_file"
            mysql -h localhost -u root -P 4000 < "$sql_file"
            
            if [ $? -eq 0 ]; then
                echo "Successfully executed: $sql_file"
            else
                echo "Failed to execute: $sql_file"
                exit 1
            fi
        fi
    done
    
    echo "All SQL files executed successfully"
else
    echo "No SQL files found in /sql directory"
fi

# Keep the container running
wait