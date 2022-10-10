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

2. Retrieve your Bitwarden self-hosted installation ID and key

    This is used to contact use in case of essential security update, validate licensing and authenticate your server to push notifications relays.

    Connect to `https://bitwarden.com/host`, enter your e-mail address and edit :

    - `globalSettings__installation__id`
    - `globalSettings__installation__key`

3. Check `nginx/default.conf` to replace `wss://localhost` with your appropriate FQDN

4. Generate SSL certificates

    ```bash
    CERTS_DN="/C=FR/ST=IDF/L=PARIS/O=EXAMPLE" bash generate-certs.sh
    ```

5. Run the project

    ```bash
    docker-compose up -d
    ```

    The web UI will be available on ports `8080` (HTTP) or `8443` (HTTPS)

## Usage for Kubernetes (Helm)

I expect you to have a K8S instance configured and ready to be accessed by your `kubectl` CLI. You must have `helm` installed too.

I've used [Scaleway Kapsule](https://www.scaleway.com/en/kubernetes-kapsule) to perform my tests. This is an easy way to have a Kubernetes cluster quickly ready.

1. Copy and edit `./kubernetes/values.yaml` file variables

    ```bash
    cp ./kubernetes/values.example.yaml ./kubernetes/values.yaml
    ```

2. Configure certs & secrets

    I recommend to copy the following commands in a text editor, replace values and execute it.

    ```bash
    NAMESPACE="bitwarden"
    kubectl create ns "${NAMESPACE}"

    # Certs
    IDENTITY_CERT_PASSWORD="IDENTITY_CERT_PASSWORD"
    CERTS_DN="/C=FR/ST=IDF/L=PARIS/O=EXAMPLE" \
      IDENTITY_CERT_PASSWORD="$IDENTITY_CERT_PASSWORD" \
      bash generate-certs.sh
    kubectl create secret -n "${NAMESPACE}" tls bitwarden-ca --key ./ssl/ca.key --cert ./ssl/ca.crt
    kubectl create secret -n "${NAMESPACE}" tls bitwarden-client --key ./ssl/bitwarden.key --cert ./ssl/bitwarden.crt
    kubectl create secret -n "${NAMESPACE}" generic identity --from-file ./identity/identity.pfx

    # Database credentials
    DB_PASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"
    kubectl create secret -n "${NAMESPACE}" generic globalsettings--sqlserver \
      --from-literal=connectionString="Data Source=tcp:bitwarden-mssql.${NAMESPACE},1433;Initial Catalog=vault;Persist Security Info=False;User ID=sa;Password=$DB_PASSWORD;MultipleActiveResultSets=False;Connect Timeout=30;Encrypt=True;TrustServerCertificate=True" \
      --from-literal=saPassword="$DB_PASSWORD"

    # SMTP settings
    kubectl create secret -n "${NAMESPACE}" generic globalsettings--mail--smtp \
      --from-literal=username=YOUR_SMTP_USERNAME \
      --from-literal=password=YOUR_SMTP_PASSWORD

    # Retrieve following values from https://bitwarden.com/host
    kubectl create secret -n "${NAMESPACE}" generic globalsettings--installation \
      --from-literal=id=00000000-0000-0000-0000-000000000000 \
      --from-literal=key=SECRET_INSTALLATION_KEY

    # Identity server secrets (nothing to edit)
    kubectl create secret -n "${NAMESPACE}" generic globalsettings--identityserver \
      --from-literal=certificatePassword="$IDENTITY_CERT_PASSWORD"
    kubectl create secret -n "${NAMESPACE}" generic globalsettings--internalidentitykey \
      --from-literal=value="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)"
    kubectl create secret -n "${NAMESPACE}" generic globalsettings--oidcidentityclientkey \
      --from-literal=value="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)"
    kubectl create secret -n "${NAMESPACE}" generic globalsettings--duo--akey \
      --from-literal=value="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)"
    ```

3. Deploy chart

    ```bash
    NAMESPACE="bitwarden"
    helm install bitwarden ./kubernetes \
      -f ./kubernetes/values.yaml \
      -n "${NAMESPACE}"
    ```
