provider "auth0" {
  domain    = var.auth0_domain
  api_token = var.auth0_api_key
}

locals {
  project_name            = "nginx-oidc-external-kvdb"
  resource_owner_username = "joe@test.com"
}

resource "auth0_connection" "db" {
  name     = local.project_name
  strategy = "auth0"
}

resource "auth0_client" "app" {
  name                       = local.project_name
  allowed_clients            = []
  app_type                   = "regular_web"
  oidc_conformant            = true
  token_endpoint_auth_method = "none"
  callbacks                  = ["http://localhost:8010/_codexch"]
  allowed_logout_urls        = ["http://localhost:8010"]
  grant_types                = ["authorization_code"]
}

resource "auth0_connection_client" "app_to_db" {
  connection_id = auth0_connection.db.id
  client_id     = auth0_client.app.id
}

data "auth0_client" "api_explorer_app" {
  name = "API Explorer Application"
}

resource "auth0_connection_client" "api_explorer_app_to_db" {
  connection_id = auth0_connection.db.id
  client_id     = data.auth0_client.api_explorer_app.id
}

resource "random_password" "user_password" {
  length  = 16
  special = false
}

resource "auth0_user" "user" {
  depends_on = [
    auth0_connection_client.api_explorer_app_to_db
  ]
  connection_name = auth0_connection.db.name
  email           = local.resource_owner_username
  email_verified  = true
  password        = random_password.user_password.result
}

resource "null_resource" "tmp_dir" {
  triggers = {
    once = local.project_name
  }

  provisioner "local-exec" {
    command = "mkdir ${path.module}/.tmp"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${path.module}/.tmp"
  }
}

resource "local_file" "nginx_external_kvdb_conf" {
  depends_on = [
    null_resource.tmp_dir
  ]
  content = templatefile(
    "files/templates/external_kvdb.server_conf.tpl",
    {
      etcd3_api_endpoint = "http://etcd:2379"
    }
  )
  filename = "${path.module}/.tmp/external_kvdb.server_conf"
}

resource "local_file" "nginx_oidc_conf" {
  depends_on = [
    null_resource.tmp_dir
  ]
  content = templatefile(
    "files/templates/openid_connect_configuration.conf.tpl",
    {
      auth0_domain        = var.auth0_domain,
      auth0_client_id     = auth0_client.app.client_id,
      auth0_client_secret = auth0_client.app.client_secret
    }
  )
  filename = "${path.module}/.tmp/openid_connect_configuration.conf"
}

resource "random_password" "etcd_root_password" {
  length  = 16
  special = false
}

resource "local_file" "docker_compose" {
  depends_on = [
    null_resource.tmp_dir
  ]
  content = templatefile(
    "files/templates/docker-compose.yaml.tpl",
    {
      nginx_plus_docker_image = var.nginx_plus_docker_image
      etcd_root_password      = random_password.etcd_root_password.result
    }
  )
  filename = "${path.module}/.tmp/docker-compose.yaml"
}

