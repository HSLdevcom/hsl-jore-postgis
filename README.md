# HSL Jore postgis

This is basically the [mdillon/postgis](https://hub.docker.com/r/mdillon/postgis/) image, but with an added init script that downloads the latest dump from Azure blob storage and restores it into the database on startup.

Use the `AZURE_STORAGE_CONTAINER` env var to select the container from which to get the dump. It defaults to `joredumps`. The script will then select the newest blob available in that container and feed it to `pg_restore`.

Note that the script will NOT run if the postgres_data directory already contains a database. This is exactly as we want to behave, as we only need to restore the DB if it does not exist.

Make sure the `AZURE_STORAGE_KEY` and `AZURE_STORAGE_ACCOUNT` env vars are set with appropriate values so that the script can download the dump.
