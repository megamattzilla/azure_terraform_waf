# Introduction 
Highly Scalable ASM solution in Azure.  ALB will target a pool of stand-alone ASM instances that have their configuration synchronized via automation (Ansible + AS3).  
Requires TMOS 15.1.x for deployment

# Getting Started
To setup your environment, you'll need to follow these processes
1.    Deploy shared resources: follow README doc in the IaC-vault folder 
2.    Deploy environment: follow README doc in the IaC folder
3.    Deploy CM folder to onboard LTM + ASM configuration 

![Architecture Diagram](https://github.com/megamattzilla/azure_terraform_waf/raw/main/azure_terraform_waf.png)
