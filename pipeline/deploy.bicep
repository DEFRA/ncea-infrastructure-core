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
