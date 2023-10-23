output "auth0_client_id" {
  value = module.auth0_oidc_provider.client_id
}

output "auth0_client_secret" {
  value     = module.auth0_oidc_provider.client_secret
  sensitive = true
}

output "username" {
  description = "Username of resource owner account"
  value       = module.auth0_oidc_provider.user_email
}

output "password" {
  description = "Password of resource owner account"
  value       = module.auth0_oidc_provider.user_password
  sensitive   = true
}
