param acrName string
param location string = resourceGroup().location
param acrSku string = 'Basic'
param privateEndpointName string
param vnetResourceGroup string
param vnetName string
param vnetSubnetName string
param environment string
param customTags object
param defaultTags object
// Key vault Params
param vaultName string
param tenantId string
param privateEndpointNameKv string
param kvSku object
//CosmosDb params
param cosmosAccountName string
param defaultConsistencyLevel string
param cosmosPrivateEndpoint object
param secondaryRegion string
param logAnalyticsInstanceName string
param logAnalyticsInstanceRg string
param applicationInsightsName string
param appServicePlanSku object
param appServicePlanName string
param appServicePlanKind string

// TO DO
// Get resource id of external log analytics instance - done
// Application Insights - done
// App Service plan - done
// API App - App Insights connection strings to Web apps
// Web App - App Insights connection strings to Web apps
// Cognitive search 
// Data factory with system assigned identity
// Blob storage 
// Redis cache
// Assign roles of managed identities:
// Web apps managed identities added RBAC role of get to key vault
// data factory identity assigned to key vault
// Cosmos connection strings added to API app 
// cosmos - update template to allow serverless option

// GET RESOURCE ID OF CENTRAL LOG ANALYTICS

resource logAnalyticsInstance 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  scope: resourceGroup(logAnalyticsInstanceRg) 
  name: logAnalyticsInstanceName
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
    vnetSubnetName: vnetSubnetName
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
    privateEndpointName: privateEndpointNameKv
    vnetResourceGroup: vnetResourceGroup
    vnetName: vnetName
    vnetSubnetName: vnetSubnetName
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

