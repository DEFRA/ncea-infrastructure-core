param serverFarmId string = '/subscriptions/8f54c9d1-875d-4c30-b468-ad3690c17068/resourceGroups/op-ncea-infra/providers/Microsoft.Web/serverFarms/opappserviceplan123'
param webAppName string = 'wallythewebapp123'
param location string = resourceGroup().location
param webAppVnetSubnetId string = '/subscriptions/8f54c9d1-875d-4c30-b468-ad3690c17068/resourceGroups/op-ncea-nw/providers/Microsoft.Network/virtualNetworks/vnet-op-ncea-poc/subnets/appservice-subnet'
//param defaultTags object 
param vnetResourceGroup string = 'op-ncea-nw'
param vnetName string ='vnet-op-ncea-poc'
param vnetSubnetName string = 'pe-subnet'
param disablePublicAccess bool = true
param applicationInsightsConnString string = 'InstrumentationKey=00c5f7b6-129b-499d-b957-5ee6f7e35814;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/'
param applicationInsightsVer string = '~3'
param alwaysOn bool = true
param ftpsState string = 'Disabled'
param linuxFxVersion string = 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
param dockerRegistryUrl string = 'https://mcr.microsoft.com'
param dockerRegistryUsername string = ''
param dockerRegistryPw string = ''
param minTlsVersion string = '1.2'
param httpsOnly bool = true
param privateEndpointName string = 'wallthewebappprivateendpoint2'


resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  //tags: defaultTags
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
    }    
    serverFarmId: serverFarmId
    clientAffinityEnabled: false    
    httpsOnly: httpsOnly  
    //publicNetworkAccess: 'Disabled'
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
    privateEndpointName: privateEndpointName
    resourceId: webApp.id
    subnetResourceId: '${resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${vnetSubnetName}'
  }
}
