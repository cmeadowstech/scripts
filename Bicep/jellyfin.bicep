// Parameters go here

param name string = 'jellyfin'
param location string = resourceGroup().location

@description('IP Address of your network')
param sourceIP string

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

var customData = base64('''

#cloud-config
package_upgrade: true
packages:
  - docker.io

# create the docker group
groups:
  - docker

# Add default auto created user to docker group
system_info:
  default_user:
    groups: [docker]

runcmd:
  - docker pull jellyfin/jellyfin
  - mkdir "/media/config"
  - mkdir "/media/cache"
  - docker run -d --name jellyfin --net=host --volume "/media/config:/config" --volume "/media/cache:/cache" --restart=unless-stopped jellyfin/jellyfin

''')

// Network Security Group

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: '${name}_nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow_ssh'
        properties: {
          access: 'Allow'
          description: 'Allows SSH'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: sourceIP
          sourcePortRange: '*'
        }
        type: 'string'
      }
      {
        name: 'allow_jf_web'
        properties: {
          access: 'Allow'
          description: 'Allows jellyfin web access'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '8096'
            '8920'
        ]
          direction: 'Inbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: sourceIP
          sourcePortRange: '*'
        }
        type: 'string'
      }
    ]
  }
}

// Virtual Network + Subnets

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
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }

// Gateway Subnet

      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.1.254.0/27'
        }
      }
    ]
  }
}

// VM Scale Set (Will use just a VM for now, then upgrade to Scale Set)

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: '${name}_vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: '${name}-vm'
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: customData
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkApiVersion: '2020-11-01'
      networkInterfaceConfigurations: [
        {
          name: '${name}_interface'
          properties: {
            deleteOption: 'Delete'
            ipConfigurations: [
              {
                name: '${name}_ip'
                properties: {
                  publicIPAddressConfiguration: {
                    name: '${name}_pip'
                    properties: {
                      deleteOption: 'Delete'
                    }
                    sku: {
                      name: 'Basic'
                      tier: 'Regional'
                    }
                  }
                  subnet: {
                    id: '${vnet.id}/subnets/${name}_subnet' 
                  }
                }
              }
            ]
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}
