# HSL Jore postgis

This is basically the [mdillon/postgis](https://hub.docker.com/r/mdillon/postgis/) image, but with an added init script that downloads the latest Jore dump from Azure blob storage and restores it into the database on startup.

The Jore dump is made after each Jore import. Note that this is the Jore data for karttaprojekti, not Jore history.

Make sure the `AZURE_STORAGE_KEY` and `AZURE_STORAGE_ACCOUNT` env vars are set with appropriate values so that the script can download the dump.
