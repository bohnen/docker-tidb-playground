#!/bin/bash

set -e

data_dir="$HOME/.tiup/data/playground"
mkdir -p "$data_dir"/pd "$data_dir"/tikv "$data_dir"/logs

# Start TiDB components in background with only the SQL port exposed externally.
if [ -n "$UNISTORE" ]; then
    "$HOME/.tiup/components/tidb/$TIDB_VERSION/tidb-server" --host 0.0.0.0 --config "$HOME/tidb.toml" &
else
    "$HOME/.tiup/components/pd/$TIDB_VERSION/pd-server" \
        --name=pd-0 \
        --data-dir="$data_dir/pd" \
        --peer-urls=http://127.0.0.1:2380 \
        --advertise-peer-urls=http://127.0.0.1:2380 \
        --client-urls=http://127.0.0.1:2379 \
        --advertise-client-urls=http://127.0.0.1:2379 \
        --log-file="$data_dir/logs/pd.log" \
        --initial-cluster=pd-0=http://127.0.0.1:2380 &

    sleep 2

    "$HOME/.tiup/components/tikv/$TIDB_VERSION/tikv-server" \
        --addr=127.0.0.1:20160 \
        --advertise-addr=127.0.0.1:20160 \
        --status-addr=127.0.0.1:20180 \
        --pd-endpoints=http://127.0.0.1:2379 \
        --data-dir="$data_dir/tikv" \
        --log-file="$data_dir/logs/tikv.log" &

    sleep 2

    "$HOME/.tiup/components/tidb/$TIDB_VERSION/tidb-server" \
        -P 4000 \
        --store=tikv \
        --host=0.0.0.0 \
        --status=10080 \
        --path=127.0.0.1:2379 \
        --config "$HOME/tidb.toml" \
        --log-file="$data_dir/logs/tidb.log" &
fi

# Wait for TiDB to be ready (max 30 seconds)
echo "Waiting for TiDB to start..."
timeout=120
elapsed=0

while [ $elapsed -lt $timeout ]; do
    if mysql --connect-timeout=1 -h 127.0.0.1 -u root -P 4000 -e "SELECT 1" >/dev/null 2>&1; then
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
