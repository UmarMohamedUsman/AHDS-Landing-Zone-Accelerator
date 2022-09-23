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

param hubVnetAddressPrefix string = '10.1.0.0/16'

param bastionAddressPrefix string = '10.1.1.0/24'
param jumpBoxAddressPrefix string = '10.1.3.0/24'

/*
@description('A short name for the PL that will be created between Funcs')
param privateLinkName string = 'myPL'
@description('Func id for PL to create')
param functionId string = '123131'
*/

// Variables
var owner = 'AHDS Landing Zone'


var hubVnetName = 'vnet-ahds-lz-hub-${workloadName}-${deploymentEnvironment}-${location}'

var bastionSubnetName = 'AzureBastionSubnet' // Azure Bastion subnet must have AzureBastionSubnet name, not 'snet-bast-${workloadName}-${deploymentEnvironment}-${location}'
var jumpBoxSubnetName = 'snet-jbox-${workloadName}-${deploymentEnvironment}-${location}-001'
var bastionName = 'bastion-${workloadName}-${deploymentEnvironment}-${location}'	
var bastionIPConfigName = 'bastionipcfg-${workloadName}-${deploymentEnvironment}-${location}'

var bastionSNNSG = 'nsg-bast-${workloadName}-${deploymentEnvironment}-${location}'
var jumpBoxSNNSG = 'nsg-jbox-${workloadName}-${deploymentEnvironment}-${location}'

var publicIPAddressNameBastion = 'pip-bastion-${workloadName}-${deploymentEnvironment}-${location}'

// Resources - VNet - SubNets
resource hubVnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: hubVnetName
  location: location
  tags: {
    Owner: owner
    // CostCenter: costCenter
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionAddressPrefix
          networkSecurityGroup: {
            id: bastionNSG.id
          }
        }
      }
      {
        name: jumpBoxSubnetName
        properties: {
          addressPrefix: jumpBoxAddressPrefix
          networkSecurityGroup: {
            id: jumpBoxNSG.id
          }
        }
        
      }
    ]
  }
}

// Network Security Groups (NSG)

// Bastion NSG must have mininal set of rules below
resource bastionNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: bastionSNNSG
  location: location
  properties: {
    securityRules: [
        {
          name: 'AllowHttpsInbound'
          properties: {
            priority: 120
            protocol: 'Tcp'
            destinationPortRange: '443'
            access: 'Allow'
            direction: 'Inbound'
            sourcePortRange: '*'
            sourceAddressPrefix: 'Internet'
            destinationAddressPrefix: '*'
          }              
        }
        {
          name: 'AllowGatewayManagerInbound'
          properties: {
            priority: 130
            protocol: 'Tcp'
            destinationPortRange: '443'
            access: 'Allow'
            direction: 'Inbound'
            sourcePortRange: '*'
            sourceAddressPrefix: 'GatewayManager'
            destinationAddressPrefix: '*'
          }              
        }
        {
            name: 'AllowAzureLoadBalancerInbound'
            properties: {
              priority: 140
              protocol: 'Tcp'
              destinationPortRange: '443'
              access: 'Allow'
              direction: 'Inbound'
              sourcePortRange: '*'
              sourceAddressPrefix: 'AzureLoadBalancer'
              destinationAddressPrefix: '*'
            }         
          }     
          {
              name: 'AllowBastionHostCommunicationInbound'
              properties: {
                priority: 150
                protocol: '*'
                destinationPortRanges:[
                  '8080'
                  '5701'                
                ] 
                access: 'Allow'
                direction: 'Inbound'
                sourcePortRange: '*'
                sourceAddressPrefix: 'VirtualNetwork'
                destinationAddressPrefix: 'VirtualNetwork'
              }              
          }                    
          {
            name: 'AllowSshRdpOutbound'
            properties: {
              priority: 100
              protocol: '*'
              destinationPortRanges:[
                '22'
                '3389'
              ]
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: 'VirtualNetwork'
            }              
          }       
          {
            name: 'AllowAzureCloudOutbound'
            properties: {
              priority: 110
              protocol: 'Tcp'
              destinationPortRange:'443'              
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: 'AzureCloud'
            }              
          }                                                         
          {
            name: 'AllowBastionCommunication'
            properties: {
              priority: 120
              protocol: '*'
              destinationPortRanges: [  
                '8080'
                '5701'
              ]
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: 'VirtualNetwork'
              destinationAddressPrefix: 'VirtualNetwork'
            }              
          }                     
          {
            name: 'AllowGetSessionInformation'
            properties: {
              priority: 130
              protocol: '*'
              destinationPortRange: '80'
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: 'Internet'
            }              
          }                                                                   
    ]
  }
}

resource jumpBoxNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: jumpBoxSNNSG
  location: location
  properties: {
    securityRules: [
    ]
  }
}

// Mind the PIP for bastion being Standard SKU, Static IP
resource pipBastion 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
  name: publicIPAddressNameBastion
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }  
}

resource bastion 'Microsoft.Network/bastionHosts@2020-07-01' = {
  name: bastionName
  location: location 
  tags:  {
    Owner: owner
  }
  properties: {
    ipConfigurations: [
      {
        name: bastionIPConfigName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipBastion.id             
          }
          subnet: {
            id: '${hubVnet.id}/subnets/${bastionSubnetName}' 
          }
        }
      }
    ]
  }
} 



// Output section
output hubVnetName string = hubVnetName
output hubVnetId string = hubVnet.id

output bastionSubnetName string = bastionSubnetName  
output jumpBoxSubnetName string = jumpBoxSubnetName 

output bastionSubnetid string = '${hubVnet.id}/subnets/${bastionSubnetName}'  
output jumpBoxSubnetid string = '${hubVnet.id}/subnets/${jumpBoxSubnetName}'  

