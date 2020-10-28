This Terraform will build a new resource group and create the share vault inside.  It will then store the BIG-IP password in the vault as well as a Service Principal for Ansible and AS3 service discovery to use.

Note: you must run this from the CLI as your azure user

# Requirements
An Azure Resource Group and Storage Account must exist to store the Terraform state for this module before running the terraform init command.  You can [create one](https://docs.microsoft.com/en-us/azure/terraform/terraform-backend) or simply use your existing infrastructure. 

Run the following commands to get started:
```bash
# set variables used by Azure CLI and Terraform
export RAND_HEX=`openssl rand -hex 2`
# PREFIX must not contain special characters 
export PREFIX="demo-$RAND_HEX" 
export RESOURCE_GROUP_NAME="$PREFIX-rg"
export STORAGE_ACCOUNT_NAME="`echo ${RESOURCE_GROUP_NAME//-}`sg"
export LOCATION="westus2"
export BIGIQ_PASSWORD="abc123"
export BIGIP_MASTER_KEY="replace with 24 character base64 encoded string to use as master key. Example: fqXEC6V913ivpr+efZVd/Q=="

# Login to Azure
az login

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query "[0].value" -o tsv)

# Create blob container
az storage container create --name terraform --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

# Initialize Terraform
terraform init -backend-config=storage_account_name=$STORAGE_ACCOUNT_NAME -backend-config=container_name=terraform -backend-config=key=vault-terraform.tfstate -backend-config=resource_group_name=$RESOURCE_GROUP_NAME 

# Determine what will be created
terraform plan -var "prefix=$PREFIX" -var "resource_group_name=$RESOURCE_GROUP_NAME" -var "region=$LOCATION" -var "bigiq_password=$BIGIQ_PASSWORD" -var "bigip_master_key=$BIGIP_MASTER_KEY"

# Create Azure Vault and populate the secrets
terraform apply -var "prefix=$PREFIX" -var "resource_group_name=$RESOURCE_GROUP_NAME" -var "region=$LOCATION" -var "bigiq_password=$BIGIQ_PASSWORD" -var "bigip_master_key=$BIGIP_MASTER_KEY" 
```