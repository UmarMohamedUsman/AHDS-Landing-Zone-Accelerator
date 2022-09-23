// Parameters
@description('A short name for the workload being deployed')
param workloadName string

@description('The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'dr'
])
param deploymentEnvironment string
param location string
param hubVnetId string
param hubVnetName string

param spokeVnetAddressPrefix string = '10.2.0.0/16'

param devOpsNameAddressPrefix string = '10.2.2.0/24'
param appGatewayAddressPrefix string = '10.2.4.0/24'
param privateEndpointAddressPrefix string = '10.2.5.0/24'
param backEndAddressPrefix string = '10.2.6.0/24'
param apimAddressPrefix string = '10.2.7.0/24'

// Variables
var owner = 'AHDS Landing Zone'


var spokeVnetName = 'vnet-adhs-lz-spoke-${workloadName}-${deploymentEnvironment}-${location}'

var devOpsSubnetName = 'snet-devops-${workloadName}-${deploymentEnvironment}-${location}'
var appGatewaySubnetName = 'snet-apgw-${workloadName}-${deploymentEnvironment}-${location}-001'
var privateEndpointSubnetName = 'snet-prep-${workloadName}-${deploymentEnvironment}-${location}-001'
var backEndSubnetName = 'snet-bcke-${workloadName}-${deploymentEnvironment}-${location}-001'
var apimSubnetName = 'snet-apim-${workloadName}-${deploymentEnvironment}-${location}-001'

var devOpsSNNSG = 'nsg-devops-${workloadName}-${deploymentEnvironment}-${location}'
var appGatewaySNNSG = 'nsg-apgw-${workloadName}-${deploymentEnvironment}-${location}'
var privateEndpointSNNSG = 'nsg-prep-${workloadName}-${deploymentEnvironment}-${location}'
var backEndSNNSG = 'nsg-bcke-${workloadName}-${deploymentEnvironment}-${location}'
var apimSNNSG = 'nsg-apim-${workloadName}-${deploymentEnvironment}-${location}'

var publicIPAddressName = 'pip-apimcs-${workloadName}-${deploymentEnvironment}-${location}' // 'publicIp'

// Resources - VNet - SubNets
resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: spokeVnetName
  location: location
  tags: {
    Owner: owner
    // CostCenter: costCenter
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetAddressPrefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: [
      {
        name: devOpsSubnetName
        properties: {
          addressPrefix: devOpsNameAddressPrefix
          networkSecurityGroup: {
            id: devOpsNSG.id
          }
        }
      }
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: appGatewayAddressPrefix
          networkSecurityGroup: {
            id: appGatewayNSG.id
          }
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointAddressPrefix
          networkSecurityGroup: {
            id: privateEndpointNSG.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: backEndSubnetName
        properties: {
          addressPrefix: backEndAddressPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: backEndNSG.id
          }
        }
      }
      {
        name: apimSubnetName
        properties: {
          addressPrefix: apimAddressPrefix
          networkSecurityGroup: {
            id: apimNSG.id
          }
        }
      }
    ]
  }
}

resource hubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: '${spokeVnet.name}/HUB-to-Spoke'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

resource spokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: '${hubVnetName}/Spoke-to-HUB'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
  }
}

// Network Security Groups (NSG)
resource devOpsNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: devOpsSNNSG
  location: location
  properties: {
    securityRules: [
    ]
  }
}

resource appGatewayNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: appGatewaySNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'HealthProbes'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_TLS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 111
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_AzureLoadBalancer'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}
resource privateEndpointNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: privateEndpointSNNSG
  location: location
  properties: {
    securityRules: [
    ]
  }
}

resource backEndNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: backEndSNNSG
  location: location
  properties: {
    securityRules: [
    ]
  }
}
resource apimNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: apimSNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'apim-mgmt-endpoint-for-portal'
        properties: {
          priority: 2000
          sourceAddressPrefix: 'ApiManagement'
          protocol: 'Tcp'
          destinationPortRange: '3443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'apim-azure-infra-lb'
        properties: {
          priority: 2010
          sourceAddressPrefix: 'AzureLoadBalancer'
          protocol: 'Tcp'
          destinationPortRange: '6390'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'apim-azure-storage'
        properties: {
          priority: 2000
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage'
        }
      }
      {
        name: 'apim-azure-sql'
        properties: {
          priority: 2010
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '1433'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'SQL'
        }
      }
      {
        name: 'apim-azure-kv'
        properties: {
          priority: 2020
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureKeyVault'
        }
      }
    ]
  }
}

// Public IP 
resource pip 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Output section
output spokeVnetName string = spokeVnetName
output spokeVnetId string = spokeVnet.id
 
output devOpsSubnetName string = devOpsSubnetName  
output appGatewaySubnetName string = appGatewaySubnetName  
output privateEndpointSubnetName string = privateEndpointSubnetName  
output backEndSubnetName string = backEndSubnetName  
output apimSubnetName string = apimSubnetName
 
output CICDAgentSubnetId string = '${spokeVnet.id}/subnets/${devOpsSubnetName}'  
output appGatewaySubnetid string = '${spokeVnet.id}/subnets/${appGatewaySubnetName}'  
output privateEndpointSubnetid string = '${spokeVnet.id}/subnets/${privateEndpointSubnetName}'  
output backEndSubnetid string = '${spokeVnet.id}/subnets/${backEndSubnetName}'  
output apimSubnetid string = '${spokeVnet.id}/subnets/${apimSubnetName}'  

output publicIp string = pip.id
