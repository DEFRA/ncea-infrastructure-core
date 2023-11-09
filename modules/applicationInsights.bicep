param logAnalyticsWorkspaceId string
param applicationInsightsName string
param location string = resourceGroup().location
param applicationType string = 'web'
param defaultTags object
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: defaultTags
  kind: 'web'
  properties: {
    Application_Type: applicationType
    Request_Source: 'rest'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

