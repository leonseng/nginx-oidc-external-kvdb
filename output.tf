output "username" {
  description = "Username of resource owner account"
  value       = local.resource_owner_username
}

output "password" {
  description = "Password of resource owner account"
  value       = random_password.user_password.result
  sensitive   = true
}
