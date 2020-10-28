variable "specification" {
  # must select a region that supports availability zones
  # https://docs.microsoft.com/en-us/azure/availability-zones/az-overview
  default = {
    gold = {
      region             = "eastus"
      azs                = ["1"]
      application_count  = 0
      environment        = "gold"
      cidr               = "10.0.0.0/8"
      ltm_instance_count = 1
      gtm_instance_count = 0
    }
    east = {
      region             = "eastus"
      azs                = ["1"]
      application_count  = 1
      environment        = "demoeast"
      cidr               = "10.0.0.0/8"
      ltm_instance_count = 1
      gtm_instance_count = 0
    }
    west = {
      region             = "westus2"
      azs                = ["1"]
      application_count  = 4
      environment        = "demowest"
      cidr               = "10.0.0.0/8"
      ltm_instance_count = 5
      gtm_instance_count = 0
    }
    deveast = {
      region             = "eastus"
      azs                = ["1"]
      application_count  = 3
      environment        = "demoeast"
      cidr               = "10.0.0.0/8"
      ltm_instance_count = 2
      gtm_instance_count = 1
    }
    devwest = {
      region             = "westus2"
      azs                = ["1"]
      application_count  = 4
      environment        = "demowest"
      cidr               = "10.0.0.0/8"
      ltm_instance_count = 2
      gtm_instance_count = 0
    }
    central = {
      region             = "centralus"
      azs                = ["1"]
      application_count  = 3
      environment        = "democentral"
      cidr               = "10.0.0.0/8"
      ltm_instance_count = 2
      gtm_instance_count = 0
    }
    dev = {
      region             = "westus2"
      azs                = ["1"]
      application_count  = 1
      environment        = "democentral"
      cidr               = "10.0.0.0/8"
      ltm_instance_count = 1
      gtm_instance_count = 0
    }
    default = {
      region             = "westus2"
      azs                = ["1"]
      application_count  = 2
      environment        = "demodefault"
      cidr               = "10.0.0.0/8"
      ltm_instance_count = 1
      gtm_instance_count = 0
    }
  }
}

# Application Server 
variable "appsvr_instance_type" {
  default = "Standard_B2s" # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general
}

# Telemetry Server 
variable "telemetrysvr_instance_type" {
  default = "Standard_D2s_v3" # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general
}

# Jumphost Server
variable "jumphost_instance_type" {
  default = "Standard_B2s" # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general
}

variable "prefix" {
  default = "demo"
}
variable "publickeyfile" {
  description = "public key for server builds"
  type        = string
  default     = "tftest.pub"
}
variable "privatekeyfile" {
  description = "private key for server access"
  type        = string
  default     = "tftest"
}
# BIGIP Image
# Use "az vm image list -f BIG-IP --all | grep 15.1" command to locate image information. 
variable instance_type { default = "Standard_D8s_v3" }
variable image_name { default = "f5-big-all-2slot-byol" }
variable product { default = "f5-big-ip-byol" }
variable bigip_version { default = "15.1.002000" }

#Replace with juice shop server image. 
variable app_image_id {
  description = "Juice Shop image ID from Shared Image Gallery"
  type        = string
  default     = "example/replace/with/juice/shop/server/image"
}

variable "admin_username" {
  description = "BIG-IP administrative user"
  default     = "admin"
}
## Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable DO_URL {
  description = "URL to download the BIG-IP Declarative Onboarding module"
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.11.0/f5-declarative-onboarding-1.11.0-1.noarch.rpm"
}
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable AS3_URL {
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.19.1/f5-appsvcs-3.19.1-1.noarch.rpm"
}
## Please check and update the latest TS URL from https://github.com/F5Networks/f5-telemetry-streaming/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable TS_URL {
  description = "URL to download the BIG-IP Telemetry Streaming Extension (TS) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.8.0/f5-telemetry-1.8.0-1.noarch.rpm"
}

variable "resource_group_name" {
  description = "Name of the Resource Group created by the IaC-vault module"
  type        = string
}

variable "hex_label" {
  description = "unique identifier for this deployment"
  type        = string
}

variable "bigip_password" {
  description = "password for BIG-IP applainces"
  type        = string
}
variable "service_principal_id" {
  description = "Azure Service Principal for BIG-IP to perform service discovery"
  type        = string
}

variable "service_principal_password" {
  description = "Azure Service Principal password for BIG-IP to perform service discovery"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID for BIG-IP to perform service discovery"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID for BIG-IP to perform service discovery"
  type        = string
}

variable "bigiq_license_host" {
  description = "FQDN of the BIG-IQ License Manager"
  type        = string
}

variable "bigiq_license_username" {
  description = "BIG-IQ License Manager user who has license management rights"
  type        = string
  default     = "licensor"
}

variable "bigiq_license_password" {
  description = "BIG-IQ License Manager user password"
  type        = string
}

variable "bigiq_license_licensepool" {
  description = "BIG-IQ License Pool to obtain license from"
  type        = string
  default     = "F5-BIG-MSP-LOADV4-LIC"
}

variable "bigiq_license_skuKeyword1" {
  description = "BIG-IQ License Pool SKU1"
  type        = string
  default     = "BT"
}

variable "bigiq_license_skuKeyword2" {
  description = "BIG-IQ License Pool SKU2"
  type        = string
  default     = "1G"
}

variable "bigiq_license_unitOfMeasure" {
  description = "BIG-IQ License Pool unit of measurement"
  type        = string
  default     = "yearly"
}

variable "f5_master_key" {
  description = "BIG-IP ASM Master Key"
  type        = string
}
