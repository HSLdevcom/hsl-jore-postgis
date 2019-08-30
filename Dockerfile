FROM mdillon/postgis:11

RUN apt update && apt install -y curl jq

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Add our own init script that restores the DB from a dump if the Db is not initialized yet.
# It needs to run after Postgis's init script.
COPY ./init.sh /docker-entrypoint-initdb.d/z_last_init.sh
COPY ./init.sql /docker-entrypoint-initdb.d/y_init.sql
