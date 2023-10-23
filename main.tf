resource "random_id" "id" {
  byte_length = 4
  prefix      = "nginx-oidc-ext-kvdb"
}

module "auth0_oidc_provider" {
  source = "github.com/leonseng/terraform-auth0-oidc-provider"

  object_name_prefix        = random_id.id.dec
  auth0_domain              = var.auth0_domain
  auth0_api_token           = var.auth0_api_key
  auth0_callback_urls       = ["http://localhost:8010/_codexch"]
  auth0_allowed_logout_urls = ["http://localhost:8010"]
}

resource "null_resource" "tmp_dir" {
  triggers = {
    once = random_id.id.dec
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
      auth0_client_id     = module.auth0_oidc_provider.client_id,
      auth0_client_secret = module.auth0_oidc_provider.client_secret
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

