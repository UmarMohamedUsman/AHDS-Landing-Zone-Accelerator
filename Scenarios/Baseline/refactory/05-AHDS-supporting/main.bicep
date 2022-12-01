targetScope = 'subscription'

param rgName string
param keyVaultPrivateEndpointName string
param acrPrivateEndpointName string
param functionAppPrivateEndpointName string
param saPrivateEndpointName string
param vnetName string
param subnetName string
param APIMsubnetName string
param VNetIntegrationSubnetName string
param APIMName string
param privateDNSZoneSAfileName string
param privateDNSZoneACRName string
param privateDNSZoneKVName string
param privateDNSZoneSAName string
param privateDNSZoneFunctionAppName string
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
param certPassword string
param containerNames array = [
  'bundles'
  'ndjson'
  'zip'
  'export'
  'export-trigger'
]
param hostingPlanName string
param fhirName string
param workspaceName string = 'eslzwks${uniqueString('workspacevws',utcNow('u'))}'
param functionAppName string

//var acrName = 'eslzacr${uniqueString(rgName, deployment().name)}'
//var keyvaultName = 'eslz-kv-${uniqueString(rgName, deployment().name)}'
var audience ='https://${workspaceName}-${fhirName}.fhir.azurehealthcareapis.com'
var functionContentShareName = 'function'

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

resource VNetIntegrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetName}/${VNetIntegrationSubnetName}'
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
  name: 'sa-table-pvtep-dns'
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
  name: 'sa-queue-pvtep-dns'
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

// Create FHIR service
module fhir 'modules/ahds/fhirservice.bicep' = {
  scope: resourceGroup(rg.name)
  name: fhirName
  params: {
    fhirName: fhirName
    workspaceName: workspaceName
    location: location
  }
}

// Hosting plan App Service
module hostingPlan 'modules/function/hostingplan.bicep' = {
  scope: resourceGroup(rg.name)
  name: hostingPlanName
  params: {
    hostingPlanName: hostingPlanName
    location: location
    functionWorkers: 5
  }
}

// Storage Container
module container 'modules/Storage/container.bicep' = [for name in containerNames: {
  scope: resourceGroup(rg.name)
  name: '${name}'
  params: {
    containername: name
    storageAccountName: storage.outputs.storageAccountName
  }
}]

// Storage file share
module functioncontentfileshare 'modules/Storage/fileshare.bicep' = {
  scope: resourceGroup(rg.name)
  name: functionContentShareName
  params: {
    storageAccountName: storage.outputs.storageAccountName
    functionContentShareName: functionContentShareName
  }
}

// KeyVault Secret FS-URL
module fsurlkvsecret 'modules/keyvault/kvsecrets.bicep'= {
  scope: resourceGroup(rg.name)
  name: 'fsurl'
  params: {
    kvname: keyvault.outputs.keyvaultName
    secretName: 'FS-URL'
    secretValue: audience
  }
}

// KeyVault Secret FS-TENANT-NAME
module tenantkvsecret 'modules/keyvault/kvsecrets.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'fstenant'
  params: {
    kvname: keyvault.outputs.keyvaultName
    secretName: 'FS-TENANT-NAME'
    secretValue: subscription().tenantId
  }
}

// KeyVault Secret FS-RESOURCE
module fsreskvsecret 'modules/keyvault/kvsecrets.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'fsresource'
  params: {
    kvname: keyvault.outputs.keyvaultName
    secretName: 'FS-RESOURCE'
    secretValue: audience
  }
}

// KeyVault Secret FS-STORAGEACCT
module sakvsecret 'modules/keyvault/kvsecrets.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'fsstorage'
  params: {
    kvname: keyvault.outputs.keyvaultName
    secretName: 'FBI-STORAGEACCT'
    secretValue: storage.outputs.storagecnn
  }
}

// user assigned fhirloaderid
module fnIdentity 'modules/Identity/userassigned.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'fnIdentity'
  params: {
    location: location
    identityName: 'fhirloaderid'
  }
}

// KeyVault Access fhirloaderid
module kvaccess 'modules/keyvault/keyvaultaccess.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'kvaultAccess'
  params: {
    keyvaultManagedIdentityObjectId: fnIdentity.outputs.principalId
    vaultName: keyvault.outputs.keyvaultName
  }
}

// KeyVault RBAC fnvaultrole
module fnvaultRole 'modules/Identity/kvaccess.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'fnvaultRole'
  params: {
    principalId: fnIdentity.outputs.principalId
    vaultName: keyvault.outputs.keyvaultName
  }
}

// FunctionApp
module functionApp 'modules/function/functionapp.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'functionApp'
  params: {
    functionAppName: functionAppName
    location: location
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
    storageAccountName: storage.outputs.storageAccountName
    VNetIntegrationSubnetID: VNetIntegrationSubnet.id
    functionContentShareName: functionContentShareName
    hostingPlanName: hostingPlan.outputs.serverfarmname
    kvname: keyvault.outputs.keyvaultName
    fnIdentityId: fnIdentity.outputs.identityid
  }
  dependsOn:[
    kvaccess
    fnvaultRole
    functioncontentfileshare
    fsurlkvsecret
    tenantkvsecret
    fsreskvsecret
    sakvsecret
  ]
}

// FunctionApp PE
module privateEndpointFunctionApp 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: functionAppPrivateEndpointName
  params: {
    location: location
    groupIds: [
      'sites'
    ]
    privateEndpointName: functionAppPrivateEndpointName
    privatelinkConnName: '${functionAppPrivateEndpointName}-conn'
    resourceId: functionApp.outputs.fnappid
    subnetid: servicesSubnet.id
  }
}

resource privateDNSZoneFunctionApp 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneFunctionAppName
}

module privateEndpointFunctionAppDNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'functionApp-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneFunctionApp.id
    privateEndpointName: privateEndpointFunctionApp.name
  }
}

output acrName string = acr.name
output keyvaultName string = keyvault.name
output storageName string = storage.name
