# NGINX OIDC with External Key-Value Database

An implementation of NGINX Plus as relying party for OpenID Connect authentication, with the session data stored in an external key-value database.

This is based on the [nginxinc/nginx-openid-connect](https://github.com/nginxinc/nginx-openid-connect) reference implementation, with some modifications to the sample configurations and [njs](https://nginx.org/en/docs/njs/) script to enable the use case.
