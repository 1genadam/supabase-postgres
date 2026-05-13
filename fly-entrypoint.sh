#!/bin/bash
# fly-entrypoint.sh — runs as root before handing off to docker-entrypoint.sh
# Fly volumes mount as root:root 0755. We fix ownership on the mount root
# and create the PGDATA subdirectory so postgres can initialize cleanly.
set -e

MOUNT_DIR="/data"
PGDATA_DIR="${PGDATA:-/data/pgdata}"

# Fix ownership of the volume mount root so postgres can write to it
chown postgres:postgres "${MOUNT_DIR}"
chmod 750 "${MOUNT_DIR}"

# Create PGDATA subdirectory with correct ownership
mkdir -p "${PGDATA_DIR}"
chown postgres:postgres "${PGDATA_DIR}"
chmod 700 "${PGDATA_DIR}"

echo "fly-entrypoint: ${MOUNT_DIR} → postgres owned, PGDATA=${PGDATA_DIR} ready"
exec docker-entrypoint.sh "$@"
