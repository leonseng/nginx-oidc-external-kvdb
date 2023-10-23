variable "auth0_domain" {
  type        = string
  description = "Auth0 Domain"
}

variable "auth0_api_key" {
  type        = string
  description = "Auth0 API key"
  sensitive   = true
}
