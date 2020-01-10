# HSL Jore postgis

This is basically the [mdillon/postgis](https://hub.docker.com/r/mdillon/postgis/) image, but with an added init script that downloads the latest dump from Azure blob storage and restores it into the database on startup.

Use the `AZURE_STORAGE_CONTAINER` env var to select the container from which to get the dump. It defaults to `joredumps`. The script will then select the newest blob available in that container and feed it to `pg_restore`.

Note that the script will NOT run if the postgres_data directory already contains a database. This is exactly as we want to behave, as we only need to restore the DB if it does not exist.

Make sure the `AZURE_STORAGE_KEY` and `AZURE_STORAGE_ACCOUNT` secrets are set through Docker with appropriate values so that the script can access the dump.

## Running locally without Docker Swarm.

You can also run the image locally without using Docker Swarm and Secrets by setting the `AZURE_STORAGE_KEY`, `AZURE_STORAGE_ACCOUNT` and `AZURE_STORAGE_CONTAINER` as environment variables on container startup.

Build image:
```
docker build -t hsl-jore-postgis .
```
```
docker run -d -p 5432:5432 --name hsl-jore-postgis -v jore-data:/var/lib/postgresql/data -e POSTGRES_PASSWORD=postgres -e AZURE_STORAGE_ACCOUNT=placeholder -e AZURE_STORAGE_KEY=placeholder -e AZURE_STORAGE_CONTAINER=placeholder hsl-jore-postgis
```
The command starts a hsl-jore-postgis container with a newly created volume `jore-data` running in the host port 5432. Follow the dump download and restore process with
`docker logs -f hsl-jore-postgis`. If you want to re-download and restore the dump after initial restore, make sure to first remove the Docker volume `jore-data` with `docker volume rm jore-data` as the script runs only if a database does not already exist on the volume.
