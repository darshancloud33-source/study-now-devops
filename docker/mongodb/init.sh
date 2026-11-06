#!/bin/bash
set -e

mongosh --quiet \
  --username "$MONGO_INITDB_ROOT_USERNAME" \
  --password "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --eval "
    db = db.getSiblingDB('study_now');
    db.createUser({
      user: '$MONGO_APP_USERNAME',
      pwd: '$MONGO_APP_PASSWORD',
      roles: [{ role: 'readWrite', db: 'study_now' }]
    });
  "
