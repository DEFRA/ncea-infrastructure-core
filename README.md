# Welcome to the NCEA INFRASTRUCTURE Repository

This repository contains assets necessary for setup and configuration of the DEFRA NCEA service.

1. Azure Kubernetes Environment setup. There are two Powershell scripts in the directory /aksEnvSetup that need to be run after the provisioning of a new AKS environment. These are 1 run only events.
   1.  /aksEnvSetup/acreate-aks-workload-identity.ps1 <br/>
   This will configure AKS workload identity and associate managed identities with kubernetes service accounts. Follow instructions in the script or see DEFRA NCEA project wiki for further details. <br/>
   For further information about workload identity see https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview?tabs=dotnet 
   1. /aksEnvSetup/deploy-internal-nginx.ps1 <br/>
   This will deploy the kubernetes nginx controller configured in internal mode. Follow instructions in the script or see DEFRA NCEA project wiki for further details. <br/>
1. Azure Automation scripts. There are two powershell automation scripts.
   1. /azAutomation/automation-start-stop-aks-nodes.ps1 <br/>
   This script will stop and start all nodes within an AKS cluster on a schedule.
   1. /azAutomation/automation-start-stop-appgw.ps1   <br/>
   This script will stop and start the azure application gateway on a schedule. 
1. The /charts directory contains the following HELM charts that are required to be deployed prior to GeoNetwork. 
   1. /charts/elasticsearch <br/>
   The chart was cloned from https://github.com/elastic/helm-charts/blob/main/README.md and modified for our requirements. <br/>
   Modifications are as follows:
     1. Addition of a persistent storage class for Azure disks that use zone redundant storage.  
     1. Addition of a storage class that uses azure files storage and mounts it as '/usr/share/elasticsearch/backup' <br/>
     This is so that elastic snapshot backups can be configured in Kibana. <br/>
     This helm chart is deployed from a Azure DevOps pipeline. 
   1.  /charts/kibana <br/>
   The chart was cloned from https://github.com/elastic/helm-charts/blob/main/README.md and modified for our requirements. <br/>
   This helm chart is deployed from a Azure DevOps pipeline. 


# Pre-requisites

1. An integrated development environment such as Visual Studio Code.
2. Azure Cli installed: https://learn.microsoft.com/en-us/cli/azure/
3. Install Azure Bicep Tool: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

# Bicep modules

- Module directory: /modules
- Modules such as privateEndpoints.bicep, keyVaults.bicep & containerRegistries.bicep have been copied from 'https://dev.azure.com/defragovuk/DEFRA-DEVOPS-COMMON/_git/Defra.Infrastructure.Common'
- Some modules directly reference the Azure Bicep Registry : https://azure.github.io/bicep-registry-modules/
- Some modules have been written and customized

# Structure

All modules are called from main.bicep. Parameters are passed into to modules.

# Deploying directly from Azure Cli

To test the templates follow these steps:
<br/>
1. Create a copy of the deploy-paramters.json and populate accordingly.
2. Login to azure with the cli 'az login'
3. A virtual network will already need to be in place, ensure that the parameters reflect the correct name, resource groups and subnet
4. Ensure an appropriate resource group has been created.
5. Use the cli to validate 'az deployment group create --resource-group NCE-IAC-POC --template-file main.bicep --parameters deploy-parameters.json --what-if'
6. If okay deploy 'az deployment group create --resource-group NCE-IAC-POC --template-file main.bicep --parameters deploy-parameters.json'

# Pipelines

The intention is to integrate this IaC with an Azure DevOps pipeline that will manage the deployment to each environment.

Intended stages and structure of the Azure DevOps pipeline will be:

1. Stage 1: Lint. Use 'az bicep build --file pipeline/main.bicep
A bicepconfig.json file defines the linting rules. If the code falls outside of this the task will fail and the code will need to be corrected.
2. Stage 2: Validate code. Use either 'AzureResourceManagerTemplateDeployment@3' or 'AzureCLI@2' task to validate bicep code. Any errors in the code will fail. 
3. Stage 3: If available use a template analyzer security tool to scan the IaC for any known vulnerabilities (https://github.com/Azure/template-analyzer)
4. Stage 4: Preview changes. Run bicep deployment with 'what if' switch. Manually review changes before approval to deploy.
5. Stage 5: Deploy development.
6. Stage 6: Deploy other environments

# TODO

The root of the repo contains a spreadsheet called 'Infrastructure LLD.xlxs'
There is a tab titled 'TODO' that lists the currently known deliverables of the IaC.

