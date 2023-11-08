/*
Description : This module creates Virtual Network and subnets in a network.

To Do       : None

Cmd Help:     
az deployment group what-if --name demodeployment  --template-file vnet-subnet.bicep -g examplerg01  
az deployment group create --name demodeployment  --template-file vnet-subnet.bicep -g examplerg01  
*/

@description('Vnet object with subnets, nsgid, routetableid and with peerings')
param paramVnet object = {
    name: 'vnet-op-ncea-poc'
    location: 'uksouth'
    resourceGroup: 'op-ncea-nw'
    subscriptionId: '8f54c9d1-875d-4c30-b468-ad3690c17068'
    addressPrefixes: [
        '10.8.0.0/22'
    ]
    subnets: [
        {
            name: 'pe-subnet'
            subnetPrefix: '10.8.0.0/24'
            nsgId: ''
            routeTableId: ''
        }
        {
            name: 'appservice-subnet'
            subnetPrefix: '10.8.1.0/24'
            nsgId: ''
            routeTableId: ''
        }
        {
            name: 'APIM-DELEGATED-subnet'
            subnetPrefix: '10.8.2.0/24'
            nsgId: ''
            routeTableId: ''
        }
    ]
}

resource resVnet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
    name: paramVnet.name
    location: paramVnet.location
    properties: {
        addressSpace: {
            addressPrefixes: paramVnet.addressPrefixes
        }
        subnets: [for subnet in paramVnet.subnets: {
            name: subnet.name
            properties: {
                addressPrefix: subnet.subnetPrefix
                networkSecurityGroup: subnet.nsgId == '' ? null : {
                    id: '/subscriptions/${paramVnet.subscriptionId}/resourceGroups/${paramVnet.resourceGroup}/providers/Microsoft.Network/networkSecurityGroups/${subnet.nsgId}'
                }
                routeTable: subnet.routeTableId == '' ? null : {
                    id: '/subscriptions/${paramVnet.subscriptionId}/resourceGroups/${paramVnet.resourceGroup}/providers/Microsoft.Network/routeTables/${subnet.routeTableId}'
                }
            }
        }]
    }
}
