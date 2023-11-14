/*
Description : This module creates Virtual Network and subnets in a network.

To Do       : None

Cmd Help:     
az deployment group what-if --name demodeployment  --template-file vnet-subnet.bicep -g examplerg01  
az deployment group create --name demodeployment  --template-file vnet-subnet.bicep -g examplerg01  
*/

@description('Vnet object with subnets, nsgid, routetableid and with peerings')
param paramVnet object = {
    name: 'vnet-snd-ncea-poc'
    location: 'uksouth'
    resourceGroup: 'NCEA-NW-POC'
    subscriptionId: 'eaabc851-0376-4a4e-a983-644d04a6ac87'
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
