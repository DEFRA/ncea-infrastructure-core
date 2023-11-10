param appServicePlanName string
param location string = resourceGroup().location
param appServicePlanSku object
param appServicePlanKind string
param workerSize string = '0'
param workerSizeId string = '0'
param numberOfWorkers string = '1'
param defaultTags object

resource appServicePlan 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: appServicePlanName
  location: location
  kind: appServicePlanKind
  tags: defaultTags
  properties: {
    name: appServicePlanName
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
    reserved: true
    zoneRedundant: false
  }
  sku: appServicePlanSku
}

output appServicePlanId string = appServicePlan.id
