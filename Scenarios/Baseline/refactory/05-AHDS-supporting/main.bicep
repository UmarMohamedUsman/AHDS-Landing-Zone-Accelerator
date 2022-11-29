targetScope = 'subscription'

param rgName string
param keyVaultPrivateEndpointName string
param acrPrivateEndpointName string
param saPrivateEndpointName string
param vnetName string
param subnetName string
param APIMsubnetName string
param APIMName string
param privateDNSZoneSAfileName string
param privateDNSZoneACRName string
param privateDNSZoneKVName string
param privateDNSZoneSAName string
param acrName string = 'eslzacr${uniqueString('acrvws',utcNow('u'))}'
param keyvaultName string = 'eslz-kv-${uniqueString('acrvws',utcNow('u'))}'
param storageAccountName string = 'eslzsa${uniqueString('ahds',utcNow('u'))}'
param storageAccountType string
param location string = deployment().location
param appGatewayName string
param appGatewaySubnetName string
param availabilityZones array
param appGwyAutoScale object
param appGatewayFQDN string
param primaryBackendEndFQDN string
@description('Set to selfsigned if self signed certificates should be used for the Application Gateway. Set to custom and copy the pfx file to vnet/certs/appgw.pfx if custom certificates are to be used')
param appGatewayCertType string
@secure()
param certPassword                  string

//var acrName = 'eslzacr${uniqueString(rgName, deployment().name)}'
//var keyvaultName = 'eslz-kv-${uniqueString(rgName, deployment().name)}'

module rg 'modules/resource-group/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}

resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetName}/${subnetName}'
}

module acr 'modules/acr/acr.bicep' = {
  scope: resourceGroup(rg.name)
  name: acrName
  params: {
    location: location
    acrName: acrName
    acrSkuName: 'Premium'
  }
}

module privateEndpointAcr 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: acrPrivateEndpointName
  params: {
    location: location
    groupIds: [
      'registry'
    ]
    privateEndpointName: acrPrivateEndpointName
    privatelinkConnName: '${acrPrivateEndpointName}-conn'
    resourceId: acr.outputs.acrid
    subnetid: servicesSubnet.id
  }
}

resource privateDNSZoneACR 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneACRName
}

module privateEndpointACRDNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'acr-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneACR.id
    privateEndpointName: privateEndpointAcr.name
  }
}
module keyvault 'modules/keyvault/keyvault.bicep' = {
  scope: resourceGroup(rg.name)
  name: keyvaultName
  params: {
    location: location
    keyVaultsku: 'Standard'
    name: keyvaultName
    tenantId: subscription().tenantId
    networkAction: 'Deny'
  }
}

module privateEndpointKeyVault 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: keyVaultPrivateEndpointName
  params: {
    location: location
    groupIds: [
      'Vault'
    ]
    privateEndpointName: keyVaultPrivateEndpointName
    privatelinkConnName: '${keyVaultPrivateEndpointName}-conn'
    resourceId: keyvault.outputs.keyvaultId
    subnetid: servicesSubnet.id
  }
}

resource privateDNSZoneKV 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneKVName
}

module privateEndpointKVDNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'kv-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneKV.id
    privateEndpointName: privateEndpointKeyVault.name
  }
}

module storage 'modules/storage/storage.bicep' = {
  scope: resourceGroup(rg.name)
  name: storageAccountName
  params: {
    location: location
    storageAccountName: storageAccountName
    storageAccountType: storageAccountType
  }
}

module privateEndpointSA 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: saPrivateEndpointName
  params: {
    location: location
    groupIds: [
      'blob'
    ]
    privateEndpointName: saPrivateEndpointName
    privatelinkConnName: '${saPrivateEndpointName}-conn'
    resourceId: storage.outputs.storageAccountId
    subnetid: servicesSubnet.id
  }
}

resource privateDNSZoneSA 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneSAName
}

module privateEndpointSADNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'sa-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneSA.id
    privateEndpointName: privateEndpointSA.name
  }
}

module privateEndpointSAfile 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${saPrivateEndpointName}-file'
  params: {
    location: location
    groupIds: [
      'file'
    ]
    privateEndpointName: '${saPrivateEndpointName}-file'
    privatelinkConnName: '${saPrivateEndpointName}-file-conn'
    resourceId: storage.outputs.storageAccountId
    subnetid: servicesSubnet.id
  }
}

resource privateDNSZoneSAfile 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneSAfileName
}

module privateEndpointSAfileDNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'sa-file-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneSAfile.id
    privateEndpointName: privateEndpointSAfile.name
  }
}

module privateEndpointSAtable 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${saPrivateEndpointName}-table'
  params: {
    location: location
    groupIds: [
      'table'
    ]
    privateEndpointName: '${saPrivateEndpointName}-table'
    privatelinkConnName: '${saPrivateEndpointName}-table-conn'
    resourceId: storage.outputs.storageAccountId
    subnetid: servicesSubnet.id
  }
}

resource privateDNSZoneSAtable 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneSAfileName
}

module privateEndpointSAtableDNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'sa-file-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneSAtable.id
    privateEndpointName: privateEndpointSAtable.name
  }
}

module privateEndpointSAqueue 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${saPrivateEndpointName}-queue'
  params: {
    location: location
    groupIds: [
      'queue'
    ]
    privateEndpointName: '${saPrivateEndpointName}-queue'
    privatelinkConnName: '${saPrivateEndpointName}-queue-conn'
    resourceId: storage.outputs.storageAccountId
    subnetid: servicesSubnet.id
  }
}

resource privateDNSZoneSAqueue 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneSAfileName
}

module privateEndpointSAqueueDNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'sa-file-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneSAqueue.id
    privateEndpointName: privateEndpointSAqueue.name
  }
}

// APIM

resource APIMSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetName}/${APIMsubnetName}'
}

module appInsights 'modules/azmon/azmon.bicep' = {
  name: 'azmon'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    resourceSuffix: 'AHDS'
  }
}

module apimModule 'modules/apim/apim.bicep'  = {
  name: 'apimDeploy'
  scope: resourceGroup(rg.name)
  params: {
    apimName: APIMName
    apimSubnetId: APIMSubnet.id
    location: location
    appInsightsName: appInsights.outputs.appInsightsName
    appInsightsId: appInsights.outputs.appInsightsId
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
  }
}

module apimDNSRecords 'modules/vnet/privatednsrecords.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'apimDNSRecords'
  params: {
    RG: rg.name
    apimName: apimModule.outputs.apimName
  }
}

// AppGW

module publicipappgw 'modules/vnet/publicip.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'APPGW-PIP'
  params: {
    availabilityZones:availabilityZones
    location: location
    publicipName: 'APPGW-PIP'
    publicipproperties: {
      publicIPAllocationMethod: 'Static'
    }
    publicipsku: {
      name: 'Standard'
      tier: 'Regional'
    }
  }
}

resource appgwSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetName}/${appGatewaySubnetName}'
}

module appgwIdentity 'modules/Identity/userassigned.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'appgwIdentity'
  params: {
    location: location
    identityName: 'appgwIdentity'
  }
}

module kvrole 'modules/Identity/kvrole.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'kvrole'
  params: {
    principalId: appgwIdentity.outputs.azidentity.properties.principalId
    roleGuid: 'f25e0fa2-a7c8-4377-a976-54943a77a395' //Key Vault Contributor
    keyvaultName: keyvaultName
  }
}

module certificate 'modules/vnet/certificate.bicep' = {
  name: 'certificate'
  scope: resourceGroup(rg.name)
  params: {
    managedIdentity:    appgwIdentity.outputs.azidentity
    keyVaultName:       keyvaultName
    location:           location
    appGatewayFQDN:     appGatewayFQDN
    appGatewayCertType: appGatewayCertType
    certPassword:       certPassword
  }
  dependsOn: [
    kvrole
  ]
}

module appgw 'modules/vnet/appgw.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'appgw'
  params: {
    appGwyAutoScale: appGwyAutoScale
    availabilityZones: availabilityZones
    location: location
    appgwname: appGatewayName
    appgwpip: publicipappgw.outputs.publicipId
    subnetid: appgwSubnet.id
    appGatewayIdentityId: appgwIdentity.outputs.identityid
    appGatewayFQDN: appGatewayFQDN
    keyVaultSecretId: certificate.outputs.secretUri
    primaryBackendEndFQDN: primaryBackendEndFQDN
  }
}

output acrName string = acr.name
output keyvaultName string = keyvault.name
output storageName string = storage.name
