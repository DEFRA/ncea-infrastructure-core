# Script for workload identity configuration. This will get clientid of managed identities, create AKS service account and then create the federated credentials
# Pre-requisites:
# Powershell 7 and latest azure az modules
# az cli and kubectl
# 'Azure Kubernetes Service RBAC Cluster Admin' RBAC on the target AKS cluster
# Contributor access on the target Azure subscription
# Ensure you have authenticated with azure and set the correct kubernetes context
# 'az aks get-credentials --resource-group rgname  --name myakscluster'
# 'kubectl config use-context myakscluster'
# Ensure the managed identities have been created and permissions applied.
# Populate variables below before running the script

# Set these variables

#Connect-AzAccount -Subscription "AZR-NCE-SND1"

#$geoNamespace =""
$frontNamespace = "nceafrontend"
$geoIdentity = ""
$aksName = ""
$aksRg = "" # managed identities should already exist in this resource group. 
$identities = "","","","","",""

# Create identities

ForEach ($identity in $identities ) {

  New-AzUserAssignedIdentity -Name $identity -ResourceGroupName $aksRg -Location "uksouth"

}

## Create namespaces

kubectl config use-context $aksName
#kubectl create namespace $geoNamespace
kubectl create namespace $frontNamespace

## End manual set of variables

$aks = Get-AzAksCluster -Name $aksName -ResourceGroupName $aksRg 
$aksOIDC = $aks.OidcIssuerProfile.IssuerUrl


ForEach ($identity in $identities ) {
  $namespace = $geoNamespace
  if ( $identity -notlike $geoIdentity) {
    $namespace = $frontNamespace
  }
  $clientID = Get-AzADServicePrincipal -DisplayName $identity
  $cliIDfull = $clientID.AppId
  $identityName = $identity.ToLower()

  $saccount = "
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: $cliIDfull
  name: saccount-ncea-$identityName
  namespace: $namespace
"
  Write-Output "creating AKS service account"
  $saccount | Out-File "${identity}.yaml" -Force
  kubectl apply -f "$identity.yaml"

  Write-Output "Creating federated credentials"

  New-AzFederatedIdentityCredential -ResourceGroupName $aksRg -IdentityName $identity -Name fed-identity-$identityName -Issuer $aksOIDC -Subject "system:serviceaccount:${namespace}:saccount-ncea-$identityName" -Audience "api://AzureADTokenExchange"

}

