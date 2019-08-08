#!/bin/bash
set -e

container_name=${AZURE_STORAGE_CONTAINER:=joredumps}

blob_name=$(az storage blob list --container-name $container_name --prefix jore_dump_ | jq -r 'sort_by(.properties.lastModified)[-1].name')
echo $blob_name

blob_path=/tmp/${blob_name}

if [ ! -f "$blob_path" ]; then
  az storage blob download --container-name $container_name --file $blob_path --name $blob_name
fi

export PGPASSWORD=$POSTGRES_PASSWORD

if [ -f "$blob_path" ]; then
  pg_restore -c --if-exists --no-owner -U postgres -d postgres --single-transaction $blob_path
  echo "Restore complete!"
else
  echo "Nothing downloaded or restored."
fi
