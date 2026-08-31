#!/bin/sh
set -e

# Working directory is /app (set by the Containerfile). godotenv autoloads
# ./app/.env and migrations are read from ./migrations relative to CWD.
exec /app/donjo-api
