#!/bin/sh
set -e

ROOT_PASSWORD="$(cat /opt/bitnami/mongodb/secrets/mongodb-root-password)"

mongoimport \
  --host localhost \
  --authenticationDatabase admin \
  --username root \
  --password "$ROOT_PASSWORD" \
  --db ratings-dev \
  --collection ratings \
  --drop \
  --file /docker-entrypoint-initdb.d/ratings_data.json