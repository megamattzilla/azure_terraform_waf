# file: IaC-vault/variables.tf

variable "prefix" {
  description = "Prefix for all Azure objects created"
  type        = string
}

variable "region" {
  description = "Azure Region to store the Key Vault in"
  type        = string
  default     = "westus2"
}

variable "resource_group_name" {
  description = "Azure Resource Group to create the vault in"
  type        = string
}

variable "ssh_key_name" {
  description = "name for the generated SSH key file"
  type        = string
  default     = "tftest"
}

variable "bigiq_password" {
  description = "Password to obtain license from BIG-IQ"
  type        = string
}

variable "bigip_master_key" {
  description = "24 character Base64 encoded string to be used as Big-IP master key"
  type        = string
}
