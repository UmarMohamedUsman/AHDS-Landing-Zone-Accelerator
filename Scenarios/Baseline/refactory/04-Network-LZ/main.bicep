targetScope = 'subscription'

// Parameters
param rgName string
param vnetSpokeName string
param spokeVNETaddPrefixes array
param spokeSubnets array
param rtFHIRSubnetName string
param firewallIP string
param vnetHubName string
param vnetHUBRGName string
param nsgFHIRName string
param nsgAppGWName string
param rtAppGWSubnetName string
param dhcpOptions object
param location string = deployment().location



module rg 'modules/resource-group/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}

module vnetspoke 'modules/vnet/vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: vnetSpokeName
  params: {
    location: location
    vnetAddressSpace: {
      addressPrefixes: spokeVNETaddPrefixes
    }
    vnetName: vnetSpokeName
    subnets: spokeSubnets
    dhcpOptions: dhcpOptions
  }
  dependsOn: [
    rg
  ]
}

module nsgfhirsubnet 'modules/vnet/nsg.bicep' = {
  scope: resourceGroup(rg.name)
  name: nsgFHIRName
  params: {
    location: location
    nsgName: nsgFHIRName
  }
}

module routetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(rg.name)
  name: rtFHIRSubnetName
  params: {
    location: location
    rtName: rtFHIRSubnetName
  }
}

module routetableroutes 'modules/vnet/routetableroutes.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'FHIR-to-internet'
  params: {
    routetableName: rtFHIRSubnetName
    routeName: 'FHIR-to-internet'
    properties: {
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: firewallIP
      addressPrefix: '0.0.0.0/0'
    }
  }
  dependsOn: [
    routetable
  ]
}

resource vnethub 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  scope: resourceGroup(vnetHUBRGName)
  name: vnetHubName
}

module vnetpeeringhub 'modules/vnet/vnetpeering.bicep' = {
  scope: resourceGroup(vnetHUBRGName)
  name: 'vnetpeeringhub'
  params: {
    peeringName: 'HUB-to-Spoke'
    vnetName: vnethub.name
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      remoteVirtualNetwork: {
        id: vnetspoke.outputs.vnetId
      }
    }
  }
  dependsOn: [
    vnethub
    vnetspoke
  ]
}

module vnetpeeringspoke 'modules/vnet/vnetpeering.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'vnetpeeringspoke'
  params: {
    peeringName: 'Spoke-to-HUB'
    vnetName: vnetspoke.outputs.vnetName
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      remoteVirtualNetwork: {
        id: vnethub.id
      }
    }
  }
  dependsOn: [
    vnethub
    vnetspoke
  ]
}

module privatednsACRZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsACRZone'
  params: {
    privateDNSZoneName: 'privatelink.azurecr.io'
  }
}

module privateDNSLinkACR 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNSLinkACR'
  params: {
    privateDnsZoneName: privatednsACRZone.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}

module privatednsVaultZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsVaultZone'
  params: {
    privateDNSZoneName: 'privatelink.vaultcore.azure.net'
  }
}

module privateDNSLinkVault 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNSLinkVault'
  params: {
    privateDnsZoneName: privatednsVaultZone.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}

module privatednsSAZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsSAZone'
  params: {
    privateDNSZoneName: 'privatelink.blob.core.windows.net'
  }
}

module privateDNSLinkSA 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNSLinkSA'
  params: {
    privateDnsZoneName: privatednsSAZone.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}

module privatednsSAfileZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsSAfileZone'
  params: {
    privateDNSZoneName: 'privatelink.file.core.windows.net'
  }
}

module privateDNSLinkSAfile 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNSLinkSAfile'
  params: {
    privateDnsZoneName: privatednsSAfileZone.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// APIM DNS Zones
module privatednsazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsazureapinet'
  params: {
    privateDNSZoneName: 'azure-api.net'
  }
}

module privatednsazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsazureapinetLink'
  params: {
    privateDnsZoneName: privatednsazureapinet.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}

module privatednsportalazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsportalazureapinet'
  params: {
    privateDNSZoneName: 'portal.azure-api.net'
  }
}

module privatednsportalazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsportalazureapinetLink'
  params: {
    privateDnsZoneName: privatednsportalazureapinet.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}

module privatednsdeveloperazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsdeveloperazureapinet'
  params: {
    privateDNSZoneName: 'developer.azure-api.net'
  }
}

module privatednsdeveloperazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsdeveloperazureapinetLink'
  params: {
    privateDnsZoneName: privatednsdeveloperazureapinet.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}

module privatednsmanagementazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsmanagementazureapinet'
  params: {
    privateDNSZoneName: 'management.azure-api.net'
  }
}

module privatednsmanagementazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsmanagementazureapinetLink'
  params: {
    privateDnsZoneName: privatednsmanagementazureapinet.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}

module privatednsscmazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsscmazureapinet'
  params: {
    privateDNSZoneName: 'scm.azure-api.net'
  }
}

module privatednsscmazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsscmazureapinetLink'
  params: {
    privateDnsZoneName: privatednsscmazureapinet.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module nsgappgwsubnet 'modules/vnet/nsg.bicep' = {
  scope: resourceGroup(rg.name)
  name: nsgAppGWName
  params: {
    location: location
    nsgName: nsgAppGWName
    securityRules: [
      {
        name: 'Allow443InBound'
        properties: {
          priority: 102
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowControlPlaneV1SKU'
        properties: {
          priority: 110
          sourceAddressPrefix: 'GatewayManager'
          protocol: '*'
          destinationPortRange: '65503-65534'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowControlPlaneV2SKU'
        properties: {
          priority: 111
          sourceAddressPrefix: 'GatewayManager'
          protocol: '*'
          destinationPortRange: '65200-65535'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHealthProbes'
        properties: {
          priority: 120
          sourceAddressPrefix: 'AzureLoadBalancer'
          protocol: '*'
          destinationPortRange: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

module appgwroutetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(rg.name)
  name: rtAppGWSubnetName
  params: {
    location: location
    rtName: rtAppGWSubnetName
  }
}

// Need to setup the AppGW to publish APIM
