# docker-tidb-playground

Unofficial TiDB Playground Dockerfile

A Docker container for running TiDB playground with easy setup and SQL initialization support.

## Features

- Based on Small Debian Slim Image
- Configurable TiDB version (default: v8.5.2)
- Automatic SQL file execution on startup
- Exposes TiDB (port 4000) and Dashboard (port 2379)
- Option to run in faster Unistore mode

## Prerequisites

- Docker installed on your system

## Building the Image

### Basic Build

```bash
docker build -t tidb-playground .
```

### Build with Custom TiDB Version

```bash
docker build --build-arg TIDB_VERSION=v8.1.0 -t tidb-playground:v8.1.0 .
```

## Running the Container

### Basic Run

```bash
docker run -d -p 4000:4000 -p 2379:2379 --name tidb-playground tidb-playground
```

### Run with SQL Initialization

Mount a directory containing SQL files to `/sql` in the container. SQL files will be executed in alphabetical order on startup.

```bash
docker run -d \
  -p 4000:4000 \
  -p 2379:2379 \
  -v $(pwd)/sql:/sql \
  --name tidb-playground \
  tidb-playground
```

### Run in Unistore Mode

```bash
docker run -d \
  -p 4000:4000 \
  -p 2379:2379 \
  -e UNISTORE=yes \
  --name tidb-playground \
  tidb-playground
```

## Connecting to TiDB

Once the container is running, you can connect to TiDB using any MySQL client:

```bash
mysql -h 127.0.0.1 -P 4000 -u root
```

Or using the MySQL client inside the container:

```bash
docker exec -it tidb-playground mysql -h localhost -P 4000 -u root
```

## Environment Variables

- `TIDB_VERSION`: The TiDB version to use (set during build time)
- `UNISTORE`: Set to any value to run TiDB in Unistore mode (lighter weight, single-node mode)

## SQL Initialization

Place your SQL files in a directory and mount it to `/sql` when running the container. The container will:

1. Wait for TiDB to be ready
2. Execute all `.sql` files in alphabetical order
3. Report success/failure for each file

Example SQL file structure:
```
sql/
├── 01-create-database.sql
├── 02-create-tables.sql
└── 03-insert-data.sql
```

## Stopping and Removing

```bash
# Stop the container
docker stop tidb-playground

# Remove the container
docker rm tidb-playground

# Remove the image
docker rmi tidb-playground
```

