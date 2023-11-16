param acrName string
param location string = resourceGroup().location
param acrSku string = 'Basic'
param disablePublicAccess bool = true
param privateEndpointName string
param vnetResourceGroup string
param vnetName string
param vnetSubnetName string
param environment string
param customTags object
param defaultTags object = {
  Environment: environment
  Tier: 'SHARED'
  Location: location
}

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  tags: union(defaultTags, customTags)
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
    zoneRedundancy: 'Enabled'
    publicNetworkAccess: (disablePublicAccess ? 'Disabled' : 'Enabled')
  }
}

module acrPrivateEndpoint 'privateEndpoints.bicep' = if (disablePublicAccess) {
  name: 'acrPrivateEndpoint'
  params: {
    location: location
    groupName: 'registry'
    privateEndpointName: privateEndpointName
    resourceId: acrResource.id
    subnetResourceId: '${resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${vnetSubnetName}'
  }
}

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer
