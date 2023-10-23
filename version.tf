terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.0.0"
    }
  }
}

provider "auth0" {
  domain    = var.auth0_domain
  api_token = var.auth0_api_key
}
