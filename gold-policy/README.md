# Overview
The included Ansible playbook will export the configured gold BIG-IP ASM policy and place it in source control with a datestamp tag.

# Requirements
You'll need to ensure you have Ansible install. The following instructions are for Ubuntu:
```bash
apt-add-repository ppa:ansible/ansible
sudo apt update
apt install ansible
```

You'll need to have Python PIP and the following python modules installed:
```bash
sudo apt-get install python-pip
sudo pip install msrest
sudo pip install msrestazure
sudo pip install azure-cli
sudo pip install azure-core
```

# Running Ansible
Ensure that your ansible inventory is working correctly
Setting the RESOURCE_GROUP_NAME programmatically below fails to work properly if there is more than one resource group with the *demo* prefix in your account. In that case run the command manually and export the appropriate resource group name.
```bash
az login
export RESOURCE_GROUP_NAME=`az group list --output tsv  --query "[?starts_with(name, 'demo')]|[0]".name`
sed -i 's/_resource_group_/'"$RESOURCE_GROUP_NAME"'/g' azure_rm.yml
git update-index --assume-unchanged azure_rm.yml
ansible-inventory --graph
```
if this doesn't generate a 

Export the required variables generated by Terraform in the IaC directory before running your playbook
```bash
az login

export KEYVAULT_NAME=`az keyvault list --resource-group $RESOURCE_GROUP_NAME --output tsv --query "[0].name"`
export BIGIP_PASSWORD=`az keyvault secret show --name bigip-password --vault-name $KEYVAULT_NAME --query value --output tsv`
export SERVICE_PRINCIPAL_ID=`az keyvault secret show --name service-principal-id --vault-name $KEYVAULT_NAME --query value --output tsv`
export SERVICE_PRINCIPAL_PASSWORD=`az keyvault secret show --name service-principal-password --vault-name $KEYVAULT_NAME --query value --output tsv`
export TENANT_ID=`az account show | jq ".tenantId" -r`
export SUBSCRIPTION_ID=`az account show | jq ".id" -r`
ansible-playbook ./main.yml
```
