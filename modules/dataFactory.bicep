@description('Data Factory Name')
param dataFactoryName string = 'datafactory${uniqueString(resourceGroup().id)}'

@description('Location of the data factory.')
param location string = resourceGroup().location
param disablePublicAccess bool
param vnetResourceGroup string 
param vnetName string 
param privateEndpointSubnetName string
param defaultTags object 
param publicNetworkAccessEnabled string = 'Disabled'


resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  tags: defaultTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: publicNetworkAccessEnabled
  }
}

module acrPrivateEndpoint 'privateEndpoints.bicep' = if (disablePublicAccess) {
  name: 'dataFactoryPrivateEndpoint'
  params: {
    location: location
    groupName: 'dataFactory'
    privateEndpointName: 'priv-endpoint-${dataFactoryName}'
    resourceId: dataFactory.id
    subnetResourceId: '${resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${privateEndpointSubnetName}'
  }
}

output dataFactoryIdentityObjId string = dataFactory.identity.principalId
