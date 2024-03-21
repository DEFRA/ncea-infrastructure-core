# Deployment of internal NGINX ingress controller
# This script will pull HELM chart and import it to the Azure Container Registry before applying it to AKS
# Pre-requisites:
# Powershell 7 and latest azure az modules
# az cli
# 'Azure Kubernetes Service RBAC Cluster Admin' RBAC on the target AKS cluster
# Contributor access on the Azure subscription
# HELM installed
# Ensure you have authenticated with azure and set the correct kubernetes context
# 'az aks get-credentials --resource-group rgname  --name myakscluster'
# 'kubectl config use-context myakscluster'

# TO DO 
# parameterize variables

## Set these vairables for the correct environment

$RegistryName = "" # without .azurecr.io
$InstanceCount = 1 # Number of NGINX replicas (lower environments can have 1)
$LoadBalancerIp = "" # Ensure IP is free and in the correct range IP for the AKS subnet before proceeding
$AzSubscription = ""

# Interactive authenticatation to Azure
Connect-AzAccount -Subscription $AzSubscription

# Update helm and add repo

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

#### LEAVE THESE ####

$ResourceGroup = (Get-AzContainerRegistry | Where-Object {$_.name -eq $RegistryName} ).ResourceGroupName
$SourceRegistry = "registry.k8s.io"
$ControllerImage = "ingress-nginx/controller"
$ControllerTag = "v1.8.1"
$PatchImage = "ingress-nginx/kube-webhook-certgen"
$PatchTag = "v20230407"
$DefaultBackendImage = "defaultbackend-amd64"
$DefaultBackendTag = "1.5"

# Set variable for ACR location to use for pulling images
$AcrUrl = (Get-AzContainerRegistry -ResourceGroupName $ResourceGroup -Name $RegistryName).LoginServer

########

# Import helm chart to ACR

Import-AzContainerRegistryImage -ResourceGroupName $ResourceGroup -RegistryName $RegistryName -SourceRegistryUri $SourceRegistry -SourceImage "${ControllerImage}:${ControllerTag}" -TargetTag "${ControllerImage}:${ControllerTag}"
Import-AzContainerRegistryImage -ResourceGroupName $ResourceGroup -RegistryName $RegistryName -SourceRegistryUri $SourceRegistry -SourceImage "${PatchImage}:${PatchTag}" -TargetTag "${PatchImage}:${PatchTag}"
Import-AzContainerRegistryImage -ResourceGroupName $ResourceGroup -RegistryName $RegistryName -SourceRegistryUri $SourceRegistry -SourceImage "${DefaultBackendImage}:${DefaultBackendTag}" -TargetTag "${DefaultBackendImage}:${DefaultBackendTag}"

# Use Helm to deploy an NGINX ingress controller
helm install ingress-nginx ingress-nginx/ingress-nginx `
    --namespace ingress-basic `
    --create-namespace `
    --set controller.replicaCount=$InstanceCount `
    --set controller.nodeSelector."kubernetes\.io/os"=linux `
    --set controller.image.registry=$AcrUrl `
    --set controller.image.image=$ControllerImage `
    --set controller.image.tag=$ControllerTag `
    --set controller.image.digest="" `
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux `
    --set controller.service.loadBalancerIP=$LoadBalancerIp `
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"=true `
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz `
    --set controller.admissionWebhooks.patch.image.registry=$AcrUrl `
    --set controller.admissionWebhooks.patch.image.image=$PatchImage `
    --set controller.admissionWebhooks.patch.image.tag=$PatchTag `
    --set controller.admissionWebhooks.patch.image.digest="" `
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux `
    --set defaultBackend.image.registry=$AcrUrl `
    --set defaultBackend.image.image=$DefaultBackendImage `
    --set defaultBackend.image.tag=$DefaultBackendTag `
    --set defaultBackend.image.digest="" 

