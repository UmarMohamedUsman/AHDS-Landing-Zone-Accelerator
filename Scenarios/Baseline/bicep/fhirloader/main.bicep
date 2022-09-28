param fhirName string
param workspaceName string
param location string = resourceGroup().location
param hostingPlanName string
param storageAccountName string
param vnetName string
param privateEndpointSubnetName string
param spokeRG string
param vaultName string
//param kvResourceGroupName string = spokeRG
param functionAppName string
param applicationInsightsName string
param functionSubnetName string
//param sharedRG string = spokeRG

param containerNames array = [
  'bundles'
  'ndjson'
  'zip'
  'export'
  'export-trigger'
]

var functionContentShareName = 'function'

var storageAccountType = 'Standard_LRS'

var privateStorageFileDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'
var privateEndpointStorageFileName = '${storageAccountName}-file-private-endpoint'

var privateStorageTableDnsZoneName = 'privatelink.table.${environment().suffixes.storage}'
var privateEndpointStorageTableName = '${storageAccountName}-table-private-endpoint'

var privateStorageBlobDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var privateEndpointStorageBlobName = '${storageAccountName}-blob-private-endpoint'

var privateStorageQueueDnsZoneName = 'privatelink.queue.${environment().suffixes.storage}'
var privateEndpointStorageQueueName = '${storageAccountName}-queue-private-endpoint'

var privateFADnsZoneName = 'privatelink.azurewebsites.net'
var privateEndpointFAName = '${functionAppName}-web-private-endpoint'


var audience ='https://${workspaceName}-${fhirName}.fhir.azurehealthcareapis.com'

module fhir 'modules/ahds/fhirservice.bicep' = {
  name: fhirName
  params: {
    fhirName: fhirName
    workspaceName: workspaceName
    location: location
  }
}

module hosting 'modules/function/hostingplan.bicep' = {
  name: hostingPlanName
  params: {
    hostingPlanName: hostingPlanName
    location: location
    functionWorkers: 5
  }
}


module Storage 'modules/Storage/storage.bicep' = {
  name: storageAccountName
  params: {
    storageAccountName: storageAccountName
    storageAccountType: storageAccountType
    location: location
  }
}

/*
resource Storage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}
*/


module container 'modules/Storage/container.bicep' = [for name in containerNames: {
  name: '${name}' 
  params: {
    containername: name
    storageAccountName: storageAccountName
  }
  dependsOn:[
    Storage
  ]
}]


module functioncontentfileshare 'modules/Storage/fileshare.bicep' = {
  name: functionContentShareName
  params: {
    storageAccountName: storageAccountName
    functionContentShareName: functionContentShareName
  }
  dependsOn:[
    Storage
  ]
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-07-01' existing = {
  name: vnetName
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
}



resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
 // name: privateEndpointSubnetName
  name: '${vnetName}/${privateEndpointSubnetName}'
 scope: resourceGroup(subscription().subscriptionId, spokeRG)
}


module storageFilePE 'modules/network/privateendpoint.bicep'={
  name: 'storageFilePE'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
    privateEndpointName: privateEndpointStorageFileName
    subnetid: privateEndpointSubnet.id
    groupIds: [
      'file'
    ]
    resourceId: Storage.outputs.storageid
    privatelinkConnName: 'FnStorageFilePrivateLinkConnection'
    location: location
  }
  dependsOn:[
    Storage
  ]
}

module storageFileDnsZone 'modules/network/privatednszone.bicep' = {
  name: 'FileDnsZone'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
   privateDNSZoneName: privateStorageFileDnsZoneName
   vnetid: virtualNetwork.id
  }
}

module storageFileDnsZoneGroup 'modules/network/privatednszonegroup.bicep' = {
  name: 'FileDnsZoneGroup'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
   privateEndpointName: privateEndpointStorageFileName
   privateDNSZoneId: storageFileDnsZone.outputs.privateDNSZoneId
  }
  dependsOn:[
    storageFileDnsZone
  ]
}


module storageBlobPE 'modules/network/privateendpoint.bicep'={
  name: 'storageBlobPE'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
    privateEndpointName: privateEndpointStorageBlobName
    subnetid: privateEndpointSubnet.id
    groupIds: [
      'blob'
    ]
    resourceId: Storage.outputs.storageid
    privatelinkConnName: 'FnStorageBlobPrivateLinkConnection'
    location: location
  }
  dependsOn:[
    Storage
  ]
}

module storageBlobDnsZone 'modules/network/privatednszone.bicep' = {
  name: 'BlobDnsZone'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
   privateDNSZoneName: privateStorageBlobDnsZoneName
   vnetid: virtualNetwork.id
  }
}

module storageBlobDnsZoneGroup 'modules/network/privatednszonegroup.bicep' = {
  name: 'BlobDnsZoneGroup'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
   privateEndpointName: privateEndpointStorageBlobName
   privateDNSZoneId: storageBlobDnsZone.outputs.privateDNSZoneId
  }
  dependsOn:[
    storageBlobDnsZone
  ]
}



module storageTablePE 'modules/network/privateendpoint.bicep'={
  name: 'storageTablePE'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
    privateEndpointName: privateEndpointStorageTableName
    subnetid: privateEndpointSubnet.id
    groupIds: [
      'table'
    ]
    resourceId: Storage.outputs.storageid
    privatelinkConnName: 'FnStorageTablePrivateLinkConnection'
    location: location
  }
  dependsOn:[
    Storage
  ]
}

module storageTableDnsZone 'modules/network/privatednszone.bicep' = {
  name: 'TableDnsZone'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
   privateDNSZoneName: privateStorageTableDnsZoneName
   vnetid: virtualNetwork.id
  }
}

module storageTableDnsZoneGroup 'modules/network/privatednszonegroup.bicep' = {
  name: 'TableDnsZoneGroup'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
   privateEndpointName: privateEndpointStorageTableName
   privateDNSZoneId: storageTableDnsZone.outputs.privateDNSZoneId
  }
  dependsOn:[
    storageTableDnsZone
  ]
}


module storagequeuePE 'modules/network/privateendpoint.bicep'={
  name: 'storagequeuePE'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
    privateEndpointName: privateEndpointStorageQueueName
    subnetid: privateEndpointSubnet.id
    groupIds: [
      'queue'
    ]
    resourceId: Storage.outputs.storageid
    privatelinkConnName: 'FnStorageQueuePrivateLinkConnection'
    location: location
  }
  dependsOn:[
    Storage
  ]
}

module storageQueueDnsZone 'modules/network/privatednszone.bicep' = {
  name: 'QueueDnsZone'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
   privateDNSZoneName: privateStorageQueueDnsZoneName
   vnetid: virtualNetwork.id
  }
}

module storageQueueDnsZoneGroup 'modules/network/privatednszonegroup.bicep' = {
  name: 'QueueDnsZoneGroup'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
   privateEndpointName: privateEndpointStorageQueueName
   privateDNSZoneId: storageQueueDnsZone.outputs.privateDNSZoneId
  }
  dependsOn:[
    storageQueueDnsZone
  ]
}

module fsurlkvsecret 'modules/keyvault/kvsecrets.bicep'= {
  name: 'fsurl'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
    kvname: vaultName
    secretName: 'FS-URL'
    secretValue: audience
  }
}

module tenantkvsecret 'modules/keyvault/kvsecrets.bicep' = {
  name: 'fstenant'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
    kvname: vaultName
    secretName: 'FS-TENANT-NAME'
    secretValue: subscription().tenantId
  }
}

module fsreskvsecret 'modules/keyvault/kvsecrets.bicep' = {
  name: 'fsresource'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
    kvname: vaultName
    secretName: 'FS-RESOURCE'
    secretValue: audience
  }
}

module sakvsecret 'modules/keyvault/kvsecrets.bicep' = {
  name: 'fsstorage'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
    kvname: vaultName
    secretName: 'FBI-STORAGEACCT'
    secretValue: Storage.outputs.storagecnn
  }
  dependsOn:[
    Storage
  ]
}

module fnIdentity 'modules/Identity/userassigned.bicep' = {
  name: 'fnIdentity'
  params: {
    location: location
    identityName: 'fhirloaderid'
  }
}

module kvaccess 'modules/keyvault/keyvaultaccess.bicep' = {
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  name: 'kvaultAccess'
  params: {
    keyvaultManagedIdentityObjectId: fnIdentity.outputs.principalId
    vaultName: vaultName
  }
  dependsOn:[
    fnIdentity
  ]
}

module fnvaultRole 'modules/RBAC/kvaccess.bicep' = {
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  name: 'fnvaultRole'
  params: {
    principalId: fnIdentity.outputs.principalId
    vaultName: vaultName
  }
  dependsOn:[
    fnIdentity
  ]
}

module functionApp 'modules/function/functionapp.bicep' = {
  name: 'functionApp'
  params: {
    functionAppName: functionAppName
    location: location
    applicationInsightsName: applicationInsightsName
    storageAccountName: storageAccountName
    functionSubnetName: functionSubnetName
    functionContentShareName: functionContentShareName
    vnetName: vnetName
    spokeRG: spokeRG
    hostingPlanName: hostingPlanName
    kvname: vaultName
    useridentity: 'fhirloaderid'
  }
  dependsOn:[
    Storage
    fnIdentity
    kvaccess
    fnvaultRole
    hosting
    functioncontentfileshare
    fsurlkvsecret
    tenantkvsecret
    fsreskvsecret
    sakvsecret
  ]
}



module FAPrivateEndpoint 'modules/network/privateendpoint.bicep'={
  name: 'FAPrivateEndpoint'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
    privateEndpointName: privateEndpointFAName
    subnetid: privateEndpointSubnet.id
    groupIds: [
      'sites'
    ]
    resourceId: functionApp.outputs.fnappid
    privatelinkConnName: 'FAPrivateLinkConnection'
    location: location
  }
  dependsOn:[
    functionApp
  ]
}

module FADnsZone 'modules/network/privatednszone.bicep' = {
  name: 'FADnsZone'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
   privateDNSZoneName: privateFADnsZoneName
   vnetid: virtualNetwork.id
  }
}

module FADnsZoneGroup 'modules/network/privatednszonegroup.bicep' = {
  name: 'FADnsZoneGroup'
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
  params: {
   privateEndpointName: privateEndpointFAName
   privateDNSZoneId: FADnsZone.outputs.privateDNSZoneId
  }
  dependsOn:[
    FADnsZone
    FAPrivateEndpoint
  ]
}

 