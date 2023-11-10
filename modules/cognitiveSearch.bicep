@description('Service name must only contain lowercase letters, digits or dashes, cannot use dash as the first two or last one characters, cannot contain consecutive dashes, and is limited between 2 and 60 characters in length.')
@minLength(2)
@maxLength(60)
param cogSearchInstanceName string

@allowed([
  'free'
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
@description('The pricing tier of the search service you want to create (for example, basic or standard).')
param sku string = 'standard'

@description('Replicas distribute search workloads across the service. You need at least two replicas to support high availability of query workloads (not applicable to the free tier).')
@minValue(1)
@maxValue(12)
param replicaCount int = 1

@description('Partitions allow for scaling of document count as well as faster indexing by sharding your index over multiple search units.')
@allowed([
  1
  2
  3
  4
  6
  12
])
param partitionCount int = 1

@description('Applicable only for SKUs set to standard3. You can set this property to enable a single, high density partition that allows up to 1000 indexes, which is much higher than the maximum indexes allowed for any other SKU.')
@allowed([
  'default'
  'highDensity'
])
param hostingMode string = 'default'

@description('Location for all resources.')
param location string = resourceGroup().location
param disablePublicAccess bool
param vnetResourceGroup string 
param vnetName string 
param privateEndpointSubnetName string
param privateEndpointName string
param defaultTags object 
param publicNetworkAccessEnabled string = 'Disabled'
@allowed([
  'None'
  'SystemAssigned'
])
@description('The type of managed identity, system assigned is default')
param systemAssignedIdentity string = 'SystemAssigned'

resource cogSearch 'Microsoft.Search/searchServices@2021-04-01-Preview' = {
  name: cogSearchInstanceName
  location: location
  tags: defaultTags
  sku: {
    name: sku
  }
  identity: {
    type: systemAssignedIdentity
  }
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
    hostingMode: hostingMode
    publicNetworkAccess: publicNetworkAccessEnabled
  }
}

module acrPrivateEndpoint 'privateEndpoints.bicep' = if (disablePublicAccess) {
  name: 'cogSearchPrivateEndpoint'
  params: {
    location: location
    groupName: 'searchService'
    privateEndpointName: privateEndpointName
    resourceId: cogSearch.id
    subnetResourceId: '${resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${privateEndpointSubnetName}'
  }
}
