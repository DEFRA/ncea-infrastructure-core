param vaultName string
param sku object = {
  name: 'standard'
  family: 'A'  
}
param tenantId string
param enablePublicAccess bool = false
param privateEndpointName string
param vnetResourceGroup string
param vnetName string
param vnetSubnetName string
param customTags object
param enableRbacAuthorization bool = true
param networkAclsDefaultAction string = 'Deny'
param virtualNetworkRules array = []
param accessPolicies array = []
param enableSoftDelete bool = true
param enablePurgeProtection bool = true
param location string = resourceGroup().location

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: vaultName
  location: location
  tags: customTags
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableSoftDelete: enableSoftDelete
    enablePurgeProtection: enablePurgeProtection
    tenantId: tenantId
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: networkAclsDefaultAction
      virtualNetworkRules: virtualNetworkRules
    }
    publicNetworkAccess: (enablePublicAccess ? 'Enabled' : 'Disabled')
    accessPolicies: enableRbacAuthorization ? [] : accessPolicies
    sku: sku
    enableRbacAuthorization: enableRbacAuthorization
  }
}

module keyVaultPrivateEndpoint 'privateEndpoints.bicep' = if (!(enablePublicAccess)) {
  name: 'keyVaultPrivateEndpoint'
  params: {
    location: location
    groupName: 'vault'
    privateEndpointName: privateEndpointName
    resourceId: keyVault.id
    subnetResourceId: '${resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${vnetSubnetName}'
  }
}

output keyVaultPrincipalId string = keyVault.id
