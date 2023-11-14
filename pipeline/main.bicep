param acrName string
param location string = resourceGroup().location
param acrSku string = 'Basic'
param privateEndpointName string
param vnetResourceGroup string
param vnetName string
param privateEndpointSubnetName string
param environment string
param customTags object
param defaultTags object
// Key vault Params
param vaultName string
param tenantId string
param kvSku object
//CosmosDb params
param cosmosAccountName string
param defaultConsistencyLevel string
param cosmosPrivateEndpoint object
param secondaryRegion string
param logAnalyticsInstanceName string
param logAnalyticsInstanceRg string

//App Insights params
param applicationInsightsName string

//App service plan params
param appServicePlanSku object
param appServicePlanName string
param appServicePlanKind string
// WebApp params
param webAppNameApi string
param webAppNameApiDisablePublicAccess bool
param webAppSubnetName string
param publicNetworkAccess string
// web front params
param webAppNameFront string
// cog search params
param cogSearchDisablePublicAccess bool
param cogSearchInstanceName string
//data factory params
param dataFactoryName string

// TO DO
// TIDY PARAMS UP
// Delegate subnet to Microsoft.Web * Delegate subnet to a service 'Microsoft.Web/serverFarms' CAN BE MANUAL for lab
// Blob storage 
// Redis cache
// cosmos - update template to allow serverless option
// Improve naming to reduce params
// Create cosmos collection
// Automate indexing of Cosmos db with cognitive search
// Make disabled public access conditional based on param
// Enabled managed identity on all resources - will need to fork cosmos and container reg
// Populate KeyVault:
// 1. Cosmos connection strings
// 2. Managed identities need RBAC permission of 'Key Vault Secrets User' ID = 4633458b-17de-408a-b874-0445c86b69e6
// 2.Cont. Web App identities, cosmos db, data factory,

// GET RESOURCE ID OF CENTRAL LOG ANALYTICS

resource logAnalyticsInstance 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  scope: resourceGroup(logAnalyticsInstanceRg) 
  name: logAnalyticsInstanceName
}

// Get app service subnet resource id
resource webAppSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' existing = {
  scope: resourceGroup(vnetResourceGroup) 
  name: '${vnetName}/${webAppSubnetName}'
}

module appInsights '../modules/applicationInsights.bicep' = {
  name: 'applicationInsights'
  params: {
    applicationInsightsName: applicationInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsInstance.id
    defaultTags: defaultTags
  }
}

module dataFactory '../modules/dataFactory.bicep' = {
  name: 'dataFactory'
  params: {
    dataFactoryName: dataFactoryName
    location: location
    defaultTags: defaultTags
    disablePublicAccess: cogSearchDisablePublicAccess //CORRECT PARAMS
    vnetResourceGroup: vnetResourceGroup
    vnetName: vnetName
    privateEndpointSubnetName: privateEndpointSubnetName
  }
}

module cogSearch '../modules/cognitiveSearch.bicep' = {
  name: 'cognitiveSearch'
  params: {
    cogSearchInstanceName: cogSearchInstanceName
    location: location
    defaultTags: defaultTags
    disablePublicAccess: cogSearchDisablePublicAccess
    vnetResourceGroup: vnetResourceGroup
    vnetName: vnetName
    privateEndpointSubnetName: privateEndpointSubnetName
  }
}

module webAppApi '../modules/webApp.bicep' = {
  name: 'webAppApi'
  params: {
    serverFarmId: appServicePlan.outputs.appServicePlanId
    location: location
    webAppName: webAppNameApi
    defaultTags: defaultTags
    webAppVnetSubnetId: webAppSubnet.id
    vnetResourceGroup: vnetResourceGroup
    vnetName: vnetName
    vnetSubnetName: privateEndpointSubnetName
    applicationInsightsConnString: appInsights.outputs.applicationInsightsConnString
    disablePublicAccess: webAppNameApiDisablePublicAccess
    publicNetworkAccess: publicNetworkAccess
  }
}

module webAppFront '../modules/webApp.bicep' = {
  name: 'webAppFront'
  params: {
    serverFarmId: appServicePlan.outputs.appServicePlanId
    location: location
    webAppName: webAppNameFront
    defaultTags: defaultTags
    webAppVnetSubnetId: webAppSubnet.id
    vnetResourceGroup: vnetResourceGroup
    vnetName: vnetName
    vnetSubnetName: privateEndpointSubnetName
    applicationInsightsConnString: appInsights.outputs.applicationInsightsConnString
    disablePublicAccess: webAppNameApiDisablePublicAccess
    publicNetworkAccess: publicNetworkAccess
  }
  dependsOn: [
    webAppApi
  ]
}

module appServicePlan '../modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    appServicePlanName: appServicePlanName
    location: location
    appServicePlanKind: appServicePlanKind
    appServicePlanSku: appServicePlanSku
    defaultTags: defaultTags
    
  }
}

module registry '../../Defra.Infrastructure.Common/templates/Microsoft.ContainerRegistry/registries.bicep' = {
  name: 'containerRegistry'
  params: {
    acrName: acrName
    location: location
    environment: environment
    acrSku: acrSku
    privateEndpointName: privateEndpointName
    vnetResourceGroup: vnetResourceGroup
    vnetName: vnetName
    vnetSubnetName: privateEndpointSubnetName
    customTags: customTags
    defaultTags: defaultTags
  }
}

module keyVault '../../Defra.Infrastructure.Common/templates/Microsoft.KeyVault/vaults.bicep' = {
  name: 'keyVault'
  params: {
    vaultName: vaultName
    location: location
    tenantId: tenantId
    privateEndpointName: 'priv-endpoint-${vaultName}'
    vnetResourceGroup: vnetResourceGroup
    vnetName: vnetName
    vnetSubnetName: privateEndpointSubnetName
    customTags: customTags
    sku: kvSku
  }
}

module cosmosDb '../../Defra.Infrastructure.Common/templates/Microsoft.DocumentDB/databaseAccounts.bicep' = {
  name: 'cosmosDb'
  params: {
    accountName: cosmosAccountName
    location: location
    defaultConsistencyLevel: defaultConsistencyLevel
    customTags: customTags
    defaultTags: defaultTags
    primaryRegion: location
    environment: environment
    privateEndpoint: cosmosPrivateEndpoint
    secondaryRegion: secondaryRegion
  }
}

