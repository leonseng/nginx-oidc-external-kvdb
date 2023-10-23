# OpenID Connect configuration
#
# Each map block allows multiple values so that multiple IdPs can be supported,
# the $host variable is used as the default input parameter but can be changed.
#
map $host $oidc_authz_endpoint {
    default https://${auth0_domain}/authorize;

    #www.example.com "https://my-idp/oauth2/v1/authorize";
}

map $host $oidc_authz_extra_args {
    # Extra arguments to include in the request to the IdP's authorization
    # endpoint.
    # Some IdPs provide extended capabilities controlled by extra arguments,
    # for example Keycloak can select an IdP to delegate to via the
    # "kc_idp_hint" argument.
    # Arguments must be expressed as query string parameters and URL-encoded
    # if required.
    default "";
    #www.example.com "kc_idp_hint=another_provider"
}

map $host $oidc_token_endpoint {
    default https://${auth0_domain}/oauth/token;

}

map $host $oidc_jwt_keyfile {
    default https://${auth0_domain}/.well-known/jwks.json;

}

map $host $oidc_client {
    default ${auth0_client_id};
}

map $host $oidc_pkce_enable {
    default 0;
}

map $host $oidc_client_secret {
    default "${auth0_client_secret}";
}

map $host $oidc_scopes {
    default "openid+profile+email+offline_access";
}

map $host $oidc_logout_redirect {
    # Where to send browser after requesting /logout location. This can be
    # replaced with a custom logout page, or complete URL.
    default "https://${auth0_domain}/v2/logout?returnTo=http%3A%2F%2Flocalhost:8010&client_id=${auth0_client_id}"; # Built-in, simple logout page
}

map $host $oidc_hmac_key {
    # This should be unique for every NGINX instance/cluster
    default "ChangeMe";
}

map $host $zone_sync_leeway {
    # Specifies the maximum timeout for synchronizing ID tokens between cluster
    # nodes when you use shared memory zone content sync. This option is only
    # recommended for scenarios where cluster nodes can randomly process
    # requests from user agents and there may be a situation where node "A"
    # successfully received a token, and node "B" receives the next request in
    # less than zone_sync_interval.
    default 0; # Time in milliseconds, e.g. (zone_sync_interval * 2 * 1000)
}

map $proto $oidc_cookie_flags {
    http  "Path=/; SameSite=lax;"; # For HTTP/plaintext testing
    https "Path=/; SameSite=lax; HttpOnly; Secure;"; # Production recommendation
}

map $http_x_forwarded_port $redirect_base {
    ""      $proto://$host:$server_port;
    default $proto://$host:$http_x_forwarded_port;
}

map $http_x_forwarded_proto $proto {
    ""      $scheme;
    default $http_x_forwarded_proto;
}

# ADVANCED CONFIGURATION BELOW THIS LINE
# Additional advanced configuration (server context) in openid_connect.server_conf

# JWK Set will be fetched from $oidc_jwks_uri and cached here - ensure writable by nginx user
proxy_cache_path /var/cache/nginx/jwk levels=1 keys_zone=jwk:64k max_size=1m;

# Change timeout values to at least the validity period of each token type
# keyval_zone zone=oidc_id_tokens:1M     state=conf.d/oidc_id_tokens.json     timeout=1h;
# keyval_zone zone=oidc_access_tokens:1M state=conf.d/oidc_access_tokens.json timeout=1h;
# keyval_zone zone=refresh_tokens:1M     state=conf.d/refresh_tokens.json     timeout=8h;
keyval_zone zone=oidc_id_tokens:1M      timeout=1h;
keyval_zone zone=oidc_access_tokens:1M  timeout=1h;
keyval_zone zone=refresh_tokens:1M      timeout=8h;
keyval_zone zone=oidc_pkce:128K         timeout=90s; # Temporary storage for PKCE code verifier.

keyval $cookie_auth_token $session_jwt   zone=oidc_id_tokens;     # Exchange cookie for JWT
keyval $cookie_auth_token $access_token  zone=oidc_access_tokens; # Exchange cookie for access token
keyval $cookie_auth_token $refresh_token zone=refresh_tokens;     # Exchange cookie for refresh token
keyval $request_id $new_session          zone=oidc_id_tokens;     # For initial session creation
keyval $request_id $new_access_token     zone=oidc_access_tokens;
keyval $request_id $new_refresh          zone=refresh_tokens; # ''
keyval $pkce_id $pkce_code_verifier      zone=oidc_pkce;

auth_jwt_claim_set $jwt_audience aud; # In case aud is an array
js_import oidc from conf.d/openid_connect.js;

# vim: syntax=nginx
