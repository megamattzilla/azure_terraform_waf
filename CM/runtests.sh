#!/bin/bash

# Get the Public IP address
ALB_NAME=$(az network lb list --resource-group $RESOURCE_GROUP_NAME --query [0].name -o tsv)
ALB_PUBLIC_IP_ID=$(az network lb frontend-ip show --lb-name $ALB_NAME --resource-group $RESOURCE_GROUP_NAME --name PublicIPAddress --query publicIpAddress.id -o tsv)
ALB_PUBLIC_IP_ADDRESS=$(az network public-ip show --ids $ALB_PUBLIC_IP_ID --query ipAddress -o tsv)

inspec exec inspec/bigip-ready --input ALB_PUBLIC_IP_ADDRESS=$ALB_PUBLIC_IP_ADDRESS