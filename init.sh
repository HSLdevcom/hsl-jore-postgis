#!/bin/bash
set -e

# Path to the Azure credentials supplied by Docker secrets
key_secret=/run/secrets/AZURE_STORAGE_KEY
account_secret=/run/secrets/AZURE_STORAGE_ACCOUNT

# Check if the credentials exist.

if [ ! -f $key_secret ]; then
  echo "Azure key not set. Dump not downloaded."
  exit 0
fi

if [ ! -f $account_secret ]; then
  echo "Azure account not set. Dump not downloaded."
  exit 0
fi

# Read the credentials so AZ CLI may use them.
AZURE_STORAGE_KEY=$(<$key_secret)
AZURE_STORAGE_ACCOUNT=$(<$account_secret)

container_name=${AZURE_STORAGE_CONTAINER:=joredumps}

blob_name=$(az storage blob list --container-name $container_name --prefix jore_dump_ --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY | jq -r 'sort_by(.properties.lastModified)[-1].name')
echo $blob_name

blob_path=/tmp/${blob_name}

if [ ! -f "$blob_path" ]; then
  az storage blob download --container-name $container_name --file $blob_path --name $blob_name --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
fi

export PGPASSWORD=$POSTGRES_PASSWORD

if [ -f "$blob_path" ]; then
  pg_restore -c --if-exists --no-owner -U postgres -d postgres --single-transaction $blob_path
  echo "Restore complete!"
else
  echo "Nothing downloaded or restored."
fi
