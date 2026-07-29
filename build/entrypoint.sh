#!/bin/bash
set -euo pipefail

RALLY_DB_FILE="/home/rally/.rally/rally.db"
RALLY_ENV_NAME="${RALLY_ENV_NAME:-openstack-v2}"
RALLY_ENV_FILE="${RALLY_ENV_FILE:-/home/rally/envfile}"

if [[ ! -f "$RALLY_DB_FILE" ]]; then
    echo "==> No Rally DB found, creating it"
    rally db create
fi

if ! rally env show "$RALLY_ENV_NAME" >/dev/null 2>&1; then
    if [[ ! -f "$RALLY_ENV_FILE" ]]; then
        echo "Environment '$RALLY_ENV_NAME' does not exist and no envfile" \
             "was mounted at $RALLY_ENV_FILE - cannot bootstrap it." >&2
        exit 1
    fi
    echo "==> Environment '$RALLY_ENV_NAME' not found, creating it from $RALLY_ENV_FILE"
    rally env create -n "$RALLY_ENV_NAME" -s "$RALLY_ENV_FILE"
fi

rally env use "$RALLY_ENV_NAME"

exec rally "$@"
