param acrName string
param location string = resourceGroup().location
param acrSku string = 'Basic'
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
param cosmosConsistencyLevel string
param cosmosPrivateEndpoint object
param cosmosCapabilities array //required to be set for serverless
param cosmosLocations array
// Cosmos collection params
param cosmosDatabaseName string
param cosmosCollectionName string
param cosmosPartitionKey string
//param secondaryRegion string
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
param dataFactoryDisablePublicAccess bool
//Storage account params
param storageAccountName string
param storageAccountSku string
param storageAccountBlobContainers array
param storageAccountZoneRedundancy bool
// Redis Cache Params
param redisCacheName string
param redisCacheSkuName string
param redisCacheCapacity int

// TO DO
// TIDY PARAMS UP
// Delegate subnet to Microsoft.Web * Delegate subnet to a service 'Microsoft.Web/serverFarms' CAN BE MANUAL for lab
// Blob storage 
// Redis cache
// Allow access to cosmos from the portal
// Automate indexing of Cosmos db with cognitive search
// Make disabled public access conditional based on param
// Populate KeyVault:
// 1. Cosmos connection strings
// 2. Managed identities need RBAC permission of 'Key Vault Secrets User' ID = 4633458b-17de-408a-b874-0445c86b69e6
// 2.Cont. Web App identities, cosmos db, data factory,
// REDIS add managed identity to Data Access Configuration

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

module redisCache 'br/public:storage/redis-cache:2.0.1' = {
  name: 'redisCache'
  params: {
    location: location
    name: redisCacheName
    tags: defaultTags
    skuName: redisCacheSkuName
    minimumTlsVersion: '1.2'
    capacity: redisCacheCapacity
    publicNetworkAccess: 'Disabled'
  }
}

module redisCachePrivEndpoint '../modules/privateEndpoints.bicep' = {
  name: 'redisCachePrivEndpoint'
  params: {
    groupName: 'redisCache'
    location: location
    privateEndpointName: 'priv-endpoint-${redisCacheName}'
    resourceId: redisCache.outputs.resourceId
    subnetResourceId: '${resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${privateEndpointSubnetName}'
  }
  dependsOn: [
    redisCache
  ]
}

module storageAccount 'br/public:storage/storage-account:3.0.1' = {
  name: 'storageAccount'
  params: {
    name: storageAccountName
    location: location
    tags: defaultTags
    sku: storageAccountSku
    isZoneRedundant: storageAccountZoneRedundancy
    identityType: 'SystemAssigned' 
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    blobContainers: storageAccountBlobContainers
    supportHttpsTrafficOnly: true
    allowSharedKeyAccess: false
    enablePublicNetworkAccess: false
    kind: 'StorageV2'
    routingPreference: {
      routingChoice: 'MicrosoftRouting'}
  }
}

output storageAccountID string = storageAccount.outputs.id

module storageAccountPrivEndpoint '../modules/privateEndpoints.bicep' = {
  name: 'storageAccountPrivEndpoint'
  params: {
    groupName: 'blob'
    location: location
    privateEndpointName: 'priv-endpoint-${storageAccountName}'
    resourceId: storageAccount.outputs.id
    subnetResourceId: '${resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${privateEndpointSubnetName}'
  }
  dependsOn: [
    storageAccount
  ]
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
    disablePublicAccess: dataFactoryDisablePublicAccess // set true for private endpoint
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
    disablePublicAccess: cogSearchDisablePublicAccess // set true for private endpoint
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
    disablePublicAccess: webAppNameApiDisablePublicAccess // set true for private endpoint
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
    disablePublicAccess: webAppNameApiDisablePublicAccess // set true for private endpoint
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
    privateEndpointName: 'priv-endpoint-${acrName}'
    vnetResourceGroup: vnetResourceGroup
    vnetName: vnetName
    vnetSubnetName: privateEndpointSubnetName // set true for private endpoint
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

module cosmosDbCollection '../modules/cosmosDbContainers.bicep' = {
  name: 'cosmosDbCollection'
  params: {
    databaseName: cosmosDatabaseName
    collectionName: cosmosCollectionName
    databaseAccount: cosmosAccountName
    partitionKey: cosmosPartitionKey
  }
  dependsOn:[
    cosmosDb
  ]
}

module cosmosDb '../modules/cosmosDb.bicep' = {
  name: 'cosmosDb'
  params: {
    accountName: cosmosAccountName
    location: location
    defaultConsistencyLevel: cosmosConsistencyLevel
    customTags: customTags
    defaultTags: defaultTags
    cosmosLocations:cosmosLocations
    environment: environment
    privateEndpoint: cosmosPrivateEndpoint
    cosmosCapabilities:cosmosCapabilities 
  }
}

