param serverFarmId string 
param webAppName string
param location string = resourceGroup().location
param webAppVnetSubnetId string 
param defaultTags object 
param vnetResourceGroup string 
param vnetName string 
param vnetSubnetName string
param disablePublicAccess bool
param publicNetworkAccess string
param applicationInsightsConnString string
param applicationInsightsVer string = '~3'
param alwaysOn bool = true
param ftpsState string = 'Disabled'
param linuxFxVersion string = 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
param dockerRegistryUrl string = 'https://mcr.microsoft.com'
param dockerRegistryUsername string = ''
param dockerRegistryPw string = ''
param minTlsVersion string = '1.2'
param httpsOnly bool = true
param http2Enabled bool = true
@allowed([
  'None'
  'SystemAssigned'
])
@description('The type of managed identity, system assigned is default')
param systemAssignedIdentity string = 'SystemAssigned'


resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: defaultTags
  identity: {
    type: systemAssignedIdentity
  }
  properties: {    
    siteConfig: {
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: applicationInsightsVer
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'Recommended'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: dockerRegistryUrl
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: dockerRegistryUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: dockerRegistryPw
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
      linuxFxVersion: linuxFxVersion
      appCommandLine: ''
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      minTlsVersion: minTlsVersion
      http20Enabled: http2Enabled               
    }    
    serverFarmId: serverFarmId
    clientAffinityEnabled: false    
    httpsOnly: httpsOnly  
    publicNetworkAccess: publicNetworkAccess
    vnetRouteAllEnabled: true
    virtualNetworkSubnetId: webAppVnetSubnetId
  }  
  dependsOn: []
}

module acrPrivateEndpoint 'privateEndpoints.bicep' = if (disablePublicAccess) {
  name: 'webAppPrivateEndpoint'
  params: {
    location: location
    groupName: 'sites'
    privateEndpointName: 'priv-endpoint-${webAppName}'
    resourceId: webApp.id
    subnetResourceId: '${resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${vnetSubnetName}'
  }
}

output webAppIdentityObjId string = webApp.identity.principalId


