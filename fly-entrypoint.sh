#!/bin/bash
# fly-entrypoint.sh — runs as root before handing off to docker-entrypoint.sh
# Fly volumes mount as root:root 0755. We:
# 1. Fix volume ownership for postgres user
# 2. Create PGDATA subdirectory
# 3. Patch /etc/postgresql/postgresql.conf data_directory to point to our volume
set -e

MOUNT_DIR="/data"
PGDATA_DIR="${PGDATA:-/data/pgdata}"

# Fix ownership of the volume mount root
chown postgres:postgres "${MOUNT_DIR}"
chmod 750 "${MOUNT_DIR}"

# Create PGDATA subdirectory with correct ownership
mkdir -p "${PGDATA_DIR}"
chown postgres:postgres "${PGDATA_DIR}"
chmod 700 "${PGDATA_DIR}"

# Patch postgresql.conf to use our volume-backed data directory
# Supabase image has data_directory = '/var/lib/postgresql/data' hardcoded
PG_CONF="/etc/postgresql/postgresql.conf"
if [ -f "${PG_CONF}" ]; then
    # Replace or append data_directory
    if grep -q "^data_directory" "${PG_CONF}"; then
        sed -i "s|^data_directory.*|data_directory = '${PGDATA_DIR}'|" "${PG_CONF}"
    else
        echo "data_directory = '${PGDATA_DIR}'" >> "${PG_CONF}"
    fi
    echo "fly-entrypoint: patched ${PG_CONF} → data_directory=${PGDATA_DIR}"
fi

echo "fly-entrypoint: ready, handing off to docker-entrypoint.sh"
exec docker-entrypoint.sh "$@"
