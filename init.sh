#!/bin/bash
set -e

# Path to the Azure credentials supplied by Docker secrets
key_secret=/run/secrets/AZURE_STORAGE_KEY
account_secret=/run/secrets/AZURE_STORAGE_ACCOUNT

# Check if the credentials exist.

if [ ! -f $key_secret ] && [ ! -v AZURE_STORAGE_KEY ]; then
  echo "Azure key not set. Dump not downloaded."
  exit 0
fi

if [ ! -f $account_secret ] && [ ! -v AZURE_STORAGE_ACCOUNT ]; then
  echo "Azure account not set. Dump not downloaded."
  exit 0
fi

# Read the credentials so AZ CLI may use them. If no env variable is set use Docker secrets.
AZURE_STORAGE_KEY=${AZURE_STORAGE_KEY:-$(<$key_secret)}
AZURE_STORAGE_ACCOUNT=${AZURE_STORAGE_ACCOUNT:-$(<$account_secret)}

container_name=${AZURE_STORAGE_CONTAINER:=joredumps}

blob_name=$(az storage blob list --container-name $container_name --prefix jore_dump_ --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY | jq -r 'sort_by(.properties.lastModified)[-1].name')

if [ $blob_name = "null" ]; then
  echo "Dump not found. Exiting."
  exit 0;
fi

echo "Latest dump found in container: ${container_name} is: ${blob_name}"

blob_path=/tmp/${blob_name}

if [ ! -f "$blob_path" ]; then
  echo "Downloading dump to file: ${blob_path}"
  az storage blob download --container-name $container_name --file $blob_path --name $blob_name --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
fi

# Initially read postgresql password from docker secrets. If it cannot be found use one from env variable.
pg_password=/run/secrets/POSTGRES_PASSWORD
if [ ! -f $pg_password ]; then
  pg_password=$POSTGRES_PASSWORD
fi

export PGPASSWORD=$pg_password

if [ -f "$blob_path" ]; then
  echo "Started database restore from dump file: ${blob_path}"
  pg_restore -c --if-exists --no-owner -U postgres -d postgres --single-transaction $blob_path
  echo "Database restore complete!"
else
  echo "Nothing downloaded or restored."
fi
