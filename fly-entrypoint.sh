#!/bin/bash
# fly-entrypoint.sh — runs as root before handing off to docker-entrypoint.sh
# Creates PGDATA subdirectory under the Fly volume mount and fixes ownership.
set -e

PGDATA_DIR="${PGDATA:-/data/pgdata}"

# Create the pgdata directory if it doesn't exist and fix ownership
if [ ! -d "${PGDATA_DIR}" ]; then
    echo "fly-entrypoint: creating ${PGDATA_DIR}"
    mkdir -p "${PGDATA_DIR}"
fi

# Ensure postgres user owns it (docker-entrypoint.sh requires this)
chown postgres:postgres "${PGDATA_DIR}"
chmod 700 "${PGDATA_DIR}"

echo "fly-entrypoint: PGDATA=${PGDATA_DIR} ready, handing off to docker-entrypoint.sh"
exec docker-entrypoint.sh "$@"
