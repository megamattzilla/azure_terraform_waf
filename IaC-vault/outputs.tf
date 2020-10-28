# file: IaC-vault/outputs.tf
output "vault_id" {
  value = azurerm_key_vault.vault.id
}

output "bigip_password" {
  value = random_password.password.result
}

output "subscription_id" {
  value = data.azurerm_subscription.primary.subscription_id
}

output "service_principal_id" {
  value = azuread_service_principal.app.application_id
}

output "service_principal_password" {
  value = random_password.sp_password.result
}

output "tenant_id" {
  value = data.azurerm_subscription.primary.tenant_id
}
