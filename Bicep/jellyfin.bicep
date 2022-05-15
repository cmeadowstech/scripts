param name string = 'jellyfin'
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: '${name}_vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${name}_subnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
          serviceEndpoints: [
            {
              locations: [
                location
              ]
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.1.254.0/27'
        }
      }
    ]
  }
}
