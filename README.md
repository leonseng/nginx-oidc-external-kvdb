# NGINX OIDC with External Key-Value Database

An implementation of NGINX Plus as relying party for OpenID Connect authentication, with the session data stored in an external key-value database (ETCD).

This is based on the [nginxinc/nginx-openid-connect](https://github.com/nginxinc/nginx-openid-connect) reference implementation, with some modifications to the sample configurations and [njs](https://nginx.org/en/docs/njs/) script to enable the use case.

## Prerequisite

- NGINX Plus Docker image
- Auth0 configured as an OpenID provider. A Terraform project [auth0-openid-provider](./auth0-openid-provider/) has been provided as an example in this repository.

## Instructions

Create `gomplate.yaml` from [gomplate.yaml.example](./gomplate.yaml.example)

Render the templates by running
```
docker run --rm \
    -v $(pwd):/host \
    hairyhenderson/gomplate \
    -d cfg=/host/gomplate.yaml \
    --file /host/docker-compose.yaml.tmpl \
    --out /host/docker-compose.yaml \
    --file /host/nginx/openid_connect_configuration.conf.tmpl \
    --out /host/nginx/openid_connect_configuration.conf
```

Start the containers
```
docker compose up -d
docker compose logs -f
```

Browse to localhost:8010 and perform the user login. You should see
1. NGINX trigger OIDC flow towards the provider, and
1. NGINX storing the session token on ETCD
```
2023/10/23 10:19:56 [info] 7#7: *1 js: Local cache miss. Attempt to fetch session information from remote KV store
2023/10/23 10:19:56 [info] 7#7: *1 js: ETCD read request body: {"key": "MmM3OWU0YjkzODJlYzc5NTVmN2I4NjA5MTQ0NGQ0ZTY="}
2023/10/23 10:19:56 [info] 7#7: *1 js: No existing session found on ETCD.
192.168.16.1 - - [23/Oct/2023:10:19:56 +0000] "GET /ip HTTP/1.1" 302 145 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36  Safari/537.36" "-"
2023/10/23 10:20:23 [info] 7#7: *1 js: OIDC refresh token stored
2023/10/23 10:20:23 [info] 7#7: *1 js: OIDC success, creating session 499904bb2353fe063387f1a879d4dff0
2023/10/23 10:20:23 [info] 7#7: *1 js: ETCD write request body: {"key": "...", "value": ..."}
2023/10/23 10:20:23 [info] 7#7: *1 js: Stored token in remote KV
```

Restart the NGINX container to simulate request hitting another NGINX instance
```
docker compose restart nginx
```

Browse to localhost:8010 again, you should see the new NGINX container obtaining the token from ETCD instead of triggering an OIDC flow towards the provider.
```
2023/10/23 10:23:32 [info] 7#7: *1 js: Local cache miss. Attempt to fetch session information from remote KV store
2023/10/23 10:23:32 [info] 7#7: *1 js: ETCD read request body: {"key": "...="}
2023/10/23 10:23:32 [info] 7#7: *1 js: Found key ... with value ...
2023/10/23 10:23:32 [info] 7#7: *1 js: Remote cache hit.
```

## Miscellaneous

To view session token on ETCD
```
docker compose exec etcd etcdctl get "" --prefix
```

To delete a session token from ETCD
```
docker compose exec etcd etcdctl del <session_token>
```
