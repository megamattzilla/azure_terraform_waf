#!/bin/bash
tf_output_file='inspec/bigip-ready-external/files/terraform.json'

# Save the Terraform data into a JSON file for InSpec to read
terraform output --json > $tf_output_file

# Set the jumphost IP address
jumphost=`cat $tf_output_file| jq '.jumphost_ip.value[0]' -r`

# Run InSpect tests from the Jumphost
inspec exec inspec/bigip-ready-external -t ssh://azureuser@$jumphost -i tftest

# Set BIG-IP variables
bigip_pwd=$(cat $tf_output_file| jq '.bigip_password.value' -r)
master_key=$(cat $tf_output_file| jq '.f5_master_key.value' -r | base64)
for bigip in $(cat $tf_output_file| jq '.bigip_mgmt_public_ips.value[]' -r)
do
    # Run InSpect tests from the BIG-IP
    inspec exec inspec/bigip-ready-internal -t ssh://admin@$bigip --password $bigip_pwd --input MASTER_KEY=$master_key
done