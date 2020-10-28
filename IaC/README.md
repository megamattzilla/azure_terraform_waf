This terraform repository uses [workspaces](https://www.terraform.io/docs/state/workspaces.html) to manage multiple parallel builds. Workspace commands include, `new`, `list`, `show`, `select`, and `delete`. The details of how workspaces are used with this repository are described below. The elements of the build configuration that are controlled by the selected workspace are described at the end of this README. 

This terraform repository supports terraform version 0.12.x. Support of terraform 0.11.x and 0.13.x (when released) subject to further testing.    

(Optional) create the SSH key pair you intend to use for the INSPEC tests. it is highly recommended that you use a keypair expressly for these builds, so that if it is compromised for any reason the breadth of impact is limited to these environments.
```bash
ssh-keygen -m PEM -t rsa -f ./tftest
```
Ensure you have an Azure access token before running ```terraform apply```.
```bash
az login
```
and accept the F5 BIG-IP marketplace license
```bash
az vm image terms accept --plan "f5-big-all-2slot-byol" --offer "f5-big-ip-byol" --publisher "f5-networks"
```

Set BASH variables for terraform and init
```bash
# set the Azure Resource Group Name
export RESOURCE_GROUP_NAME="demo-ab12-rg"
# or
export RESOURCE_GROUP_NAME=`az group list --output tsv  --query "[?starts_with(name, 'demo')]".name`

# Set the BIG-IQ hostname for license management
export BIGIQ_HOST="bigiq.example.local"

# Set remaining variables from from the Azure CLI 
export KEYVAULT_NAME=`az keyvault list --resource-group $RESOURCE_GROUP_NAME --output tsv --query "[0].name"`
export STORAGE_ACCOUNT_NAME=`az storage account list --resource-group $RESOURCE_GROUP_NAME --output tsv --query [0].name`
export HEX_LABEL=`echo $RESOURCE_GROUP_NAME | cut -d '-' -f 2`
export BIGIP_PASSWORD=`az keyvault secret show --name bigip-password --vault-name $KEYVAULT_NAME --query value --output tsv`
export SERVICE_PRINCIPAL_ID=`az keyvault secret show --name service-principal-id --vault-name $KEYVAULT_NAME --query value --output tsv`
export SERVICE_PRINCIPAL_PASSWORD=`az keyvault secret show --name service-principal-password --vault-name $KEYVAULT_NAME --query value --output tsv`
export BIGIQ_PASSWORD=`az keyvault secret show --name bigiq-password --vault-name $KEYVAULT_NAME --query value --output tsv`
export MASTER_KEY=`az keyvault secret show --name master-key --vault-name $KEYVAULT_NAME --query value --output tsv`
export SUBSCRIPTION_ID=`az account show | jq ".id" -r`
export TENANT_ID=`az account show | jq ".tenantId" -r`

# Initialize Terraform (no workspace yet)
terraform init -backend-config=storage_account_name=$STORAGE_ACCOUNT_NAME -backend-config=container_name=terraform -backend-config=key=terraform.tfstate -backend-config=resource_group_name=$RESOURCE_GROUP_NAME 

```
the first time you use one of the terraform workspaces you need to create it using the ```new``` action

```bash
terraform workspace new [east|west|central]
```
For example, if you intend to build in both the east and central workspaces you would do the following;

```bash
terraform workspace new east
terraform workspace new central
```
this will create a `terraform.tfstate.d` directory that will contain subdirectories for each workspace

Creating a new workspace will likely switch to that workspace automatically. You can also select the workspace you intend to use with the ```terraform workspace select action```. for example,
```bash
terraform workspace select east
```

You can ```plan``` and ```apply``` the terraform repository
```bash
# Initialize Terraform Workspace
terraform init -backend-config=storage_account_name=$STORAGE_ACCOUNT_NAME -backend-config=container_name=terraform -backend-config=key=terraform.tfstate -backend-config=resource_group_name=$RESOURCE_GROUP_NAME 

# Determine what Terraform will create
terraform plan -var "resource_group_name=$RESOURCE_GROUP_NAME" -var "hex_label=$HEX_LABEL" -var "bigip_password=$BIGIP_PASSWORD" -var "service_principal_id=$SERVICE_PRINCIPAL_ID" -var "service_principal_password=$SERVICE_PRINCIPAL_PASSWORD" -var "subscription_id=$SUBSCRIPTION_ID" -var "tenant_id=$TENANT_ID" -var "bigiq_license_host=$BIGIQ_HOST" -var "bigiq_license_password=$BIGIQ_PASSWORD" -var "f5_master_key=$MASTER_KEY"

# Build out environment
terraform apply -var "resource_group_name=$RESOURCE_GROUP_NAME" -var "hex_label=$HEX_LABEL" -var "bigip_password=$BIGIP_PASSWORD" -var "service_principal_id=$SERVICE_PRINCIPAL_ID" -var "service_principal_password=$SERVICE_PRINCIPAL_PASSWORD" -var "subscription_id=$SUBSCRIPTION_ID" -var "tenant_id=$TENANT_ID" -var "bigiq_license_host=$BIGIQ_HOST" -var "bigiq_license_password=$BIGIQ_PASSWORD" -var "f5_master_key=$MASTER_KEY"

# Test the environment
./runtest.sh
```

You can use terraform to destroy and recreate a specific Big-IP upon terraform apply. If a license was assigned to this device, it will need to be manually revoked. 
```bash
# Example recreate Big-IP nodes 0 and 5: 
terraform taint azurerm_virtual_machine.f5bigip[0]
terraform taint azurerm_virtual_machine.f5bigip[5]
terraform apply -var "resource_group_name=$RESOURCE_GROUP_NAME" -var "hex_label=$HEX_LABEL" -var "bigip_password=$BIGIP_PASSWORD" -var "service_principal_id=$SERVICE_PRINCIPAL_ID" -var "service_principal_password=$SERVICE_PRINCIPAL_PASSWORD" -var "subscription_id=$SUBSCRIPTION_ID" -var "tenant_id=$TENANT_ID" -var "bigiq_license_host=$BIGIQ_HOST" -var "bigiq_license_password=$BIGIQ_PASSWORD" -var "f5_master_key=$MASTER_KEY"
```
note: if you're using local state files, during an ```apply``` the state files are locked. This means you **can't** open another terminal window and select another workspace and try to run ```terraform apply```. (I may be wrong about this. An earlier version of terraform stored all the workspace state in a single tfstate file. Since they're in separate files that may allow for parallel local builds)



kick the tires, and then
```bash
terraform workspace select [east|west|central]
terraform destroy -var "resource_group_name=$RESOURCE_GROUP_NAME" -var "hex_label=$HEX_LABEL" -var "bigip_password=$BIGIP_PASSWORD" -var "service_principal_id=$SERVICE_PRINCIPAL_ID" -var "service_principal_password=$SERVICE_PRINCIPAL_PASSWORD" -var "subscription_id=$SUBSCRIPTION_ID" -var "tenant_id=$TENANT_ID" -var "bigiq_license_host=$BIGIQ_HOST" -var "bigiq_license_password=$BIGIQ_PASSWORD" -var "f5_master_key=$MASTER_KEY"
```

# Workspace Configuration
In the variables.tf there is a `specification` variable that contains HCL maps named with a reference to a workspace. For example, the map below is used when the east workspace is selected using ```terraform workspace select east```

```
        east = {
            region             = "eastus"
            azs                = ["1"]
            application_count  = 3
            environment        = "demoeast"
            cidr               = "10.0.0.0/8"
            ltm_instance_count = 2
            gtm_instance_count = 1
        }
```

if you need to create support for another workspace duplicate an existing map, add it to the array, and adjust values as appropriate. For example, if you need to add support for `francecentral` you could do as follows;

```
        east = {
            region             = "eastus"
            azs                = ["1"]
            application_count  = 3
            environment        = "demoeast"
            cidr               = "10.0.0.0/8"
            ltm_instance_count = 2
            gtm_instance_count = 1
        }
        francecentral = {
            region            = "francecentral"
            azs               = ["1"]
            application_count = 1
            environment       = "demofrcent"
            cidr              = "10.0.0.0/8"
            ltm_instance_count = 2
            gtm_instance_count = 0
        }
        west = {
            region            = "westus2"
            azs               = ["1"]
            application_count = 3
            environment       = "demowest"
            cidr              = "10.0.0.0/8"
            ltm_instance_count = 2
            gtm_instance_count = 0
        }



```

# Pipeline Configuration
TODO: 
 - document creation of service principal via ADO
 - allow ADO SP access to BIG-IP and Juiceshop shared images
 - create variable group and link it to Azure Vault created by IaC-Vault
 - upload ssh public and private keys into ADO Pipeline secure files
 - create release pipeline and link the variable group
 
 Terraform: Init
  - Display name: Terraform : init
  - Command : init
  - configuration directory: $(System.DefaultWorkingDirectory)/_poc-demo/IaC

 Terraform: Apply
  - Display name: Terraform : apply
  - Command: validate and apply
  - Configuration directory: $(System.DefaultWorkingDirectory)/_poc-demo/IaC
  - Additional command arguments: 
  ```
  -var "privatekeyfile=$(pocprivatekey.secureFilePath)" -var "publickeyfile=$(pocpublickey.secureFilePath)" -var "resource_group_name=$(resource_group_name)" -var "hex_label=$(hex_label)" -var "bigip_password=$(bigip-password)" -var "service_principal_id=$(service-principal-id)" -var "service_principal_password=$(service-principal-password)" -var "subscription_id=$(subscription-id)" -var "tenant_id=$(tenant-id)" -var "bigiq_license_host=$(bigiq_license_host)" -var "bigiq_license_password=$(bigiq_license_password)" -var "f5_master_key=$(master_key)
  ```