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
param privateEndpointNameKv string
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
param privateEndpointApiWebAppName string
param webAppNameApiDisablePublicAccess bool
param webAppSubnetName string
param publicNetworkAccess string
// web front params
param webAppNameFront string
param privateEndpointFrontWebAppName string
param cogSearchDisablePublicAccess bool
param cogSearchInstanceName string

// TO DO
// TIDY PARAMS UP 
// Get resource id of external log analytics instance - done
// Application Insights - done
// App Service plan - done
// API App - App Insights connection strings to Web apps - done
// Web App - App Insights connection strings to Web apps - done
// Delegate subnet to Microsoft.Web * Delegate subnet to a service 'Microsoft.Web/serverFarms' CAN BE MANUAL for lab
// Cognitive search - done
// Data factory with system assigned identity
// Blob storage 
// Redis cache
// Assign roles of managed identities:
// Web apps managed identities added RBAC role of get to key vault
// data factory identity assigned to key vault
// Cosmos connection strings added to API app 
// cosmos - update template to allow serverless option
// Improve naming to reduce params
// Create cosmos collection
// Automate indexing of Cosmos db with cognitive search
// MAke disabled public access conditional based on param

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
    privateEndpointName: '${cogSearchInstanceName}-privateendpoint'
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
    privateEndpointName: privateEndpointApiWebAppName
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
    privateEndpointName: privateEndpointFrontWebAppName
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
    privateEndpointName: privateEndpointNameKv
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

