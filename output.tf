output "username" {
  description = "Username of resource owner account"
  value       = module.auth0_oidc_provider.user_email
}

output "password" {
  description = "Password of resource owner account"
  value       = module.auth0_oidc_provider.user_password
  sensitive   = true
}
