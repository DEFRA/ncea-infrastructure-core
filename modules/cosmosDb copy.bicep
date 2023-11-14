@description('Location for all resources.')
param location string = resourceGroup().location

@description('Cosmos DB account name (must contain only lowercase letters, digits, and hyphens)')
@maxLength(44)
@minLength(3)
param accountName string

@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
@description('The default consistency level of the Cosmos DB account.')
param defaultConsistencyLevel string = 'Session'

@minValue(10)
@maxValue(2147483647)
@description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 2147483647. Multi Region: 100000 to 2147483647.')
param maxStalenessPrefix int = 100000

@minValue(5)
@maxValue(86400)
@description('Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
param maxIntervalInSeconds int = 300

@description('Enable public network traffic to access the account; if set to Disabled, public network traffic will be blocked even before the private endpoint is created')
param enablePublicAccess bool = false

@description('The private endpoint configuration settings')
param privateEndpoint object

@allowed([
  true
  false
])
@description('Enable system managed failover for regions')
param systemManagedFailover bool = true

@description('The primary region for the Azure Cosmos DB account.')
param primaryRegion string

@description('The secondary region for the Azure Cosmos DB account.')
param secondaryRegion string

@description('Current deployment environment. DEV, TST, etc.')
param environment string
@description('Default tags for Azure Consmos DB')
param defaultTags object = {
  Environment: environment
  Tier: 'CDN'
}
@description('Specific tags for the Azure Consmos DB, in addition to defaultTags')
param customTags object

var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}
var locations = [
  {
    locationName: primaryRegion
    failoverPriority: 0
    isZoneRedundant: false
  }
  {
    locationName: secondaryRegion
    failoverPriority: 1
    isZoneRedundant: false
  }
]

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15-preview' = {
  name: toLower(accountName)
  location: location
  tags: union(defaultTags, customTags)
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: location
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: systemManagedFailover
    publicNetworkAccess: (enablePublicAccess ? 'Enabled' : 'Disabled')
    minimalTlsVersion: 'Tls12'
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

module appConfigPrivateEndpoint 'privateEndpoints.bicep' = if (enablePublicAccess == false) {
  name: 'cosmos-db-private-endpoint'
  params: {
    location: location
    groupName: 'Sql'
    privateEndpointName: privateEndpoint.Name
    resourceId: databaseAccount.id
    subnetResourceId: '${resourceId(privateEndpoint.vnetResourceGroup, 'Microsoft.Network/virtualNetworks', privateEndpoint.vnetName)}/subnets/${privateEndpoint.vnetSubnetName}'
  }
}

output id string = databaseAccount.id