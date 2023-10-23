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
