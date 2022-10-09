# Bitwarden Docker Compose and K8S configurations

Docker Compose and Kubernetes configuration for easily deploying Bitwarden.

The [official Docker installation](https://bitwarden.com/help/install-on-premise-linux/#install-bitwarden) might be uncertain to setup or not compliant with your security standards as you need to run an untrusted _.sh_ script on your computer. This compose installation is here to fix this issue. Enjoy and star this repo !

## Usage for docker-compose

1. Copy and edit `*.env` files variables

    ```bash
    cp global.example.env global.env
    cp mssql.example.env mssql.env
    ```

    :warning: Make sure the `Password=` of the `globalSettings__sqlServer__connectionString` variable in `global.env` matches the `SA_PASSWORD` value in `mssql.env`

2. Check `nginx/default.conf` to replace `wss://localhost` with your appropriate FQDN

3. Generate SSL certificates

    ```bash
    CERTS_DN="/C=FR/ST=IDF/L=PARIS/O=EXAMPLE" bash generate-certs.sh
    ```

4. Run the project

    ```bash
    docker-compose up -d
    ```

    The web UI will be available on ports `8080` (HTTP) or `8443` (HTTPS)

## Usage for Kubernetes

TODO
