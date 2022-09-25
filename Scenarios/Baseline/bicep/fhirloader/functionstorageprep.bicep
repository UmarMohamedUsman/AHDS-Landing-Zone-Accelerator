
param location string = resourceGroup().location
param storageAccountName string
param vnetName string
param privateEndpointSubnetName string
param spokeRG string

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


module Storage 'modules/Storage/storage.bicep' = {
  name: storageAccountName
  params: {
    storageAccountName: storageAccountName
    storageAccountType: storageAccountType
    location: location
  }
}



module container 'modules/Storage/container.bicep' = [for name in containerNames: {
  name: '${name}' 
  params: {
    containername: name
    storageAccountName: storageAccountName
  }
}]


module functioncontentfileshare 'modules/Storage/fileshare.bicep' = {
  name: storageAccountName
  params: {
    storageAccountName: storageAccountName
    functionContentShareName: functionContentShareName
  }
}
/*
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-07-01' existing = {
  name: vnetName
  scope: resourceGroup(subscription().subscriptionId, spokeRG)
}

*/

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
 // name: privateEndpointSubnetName
  name: '${vnetName}/${privateEndpointSubnetName}'
 scope: resourceGroup(subscription().subscriptionId, spokeRG)
}


module storageFilePE 'modules/network/privateendpoint.bicep'={
  name: 'storageFilePE'
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
}

module storageFileDnsZone 'modules/network/privatednszone.bicep' = {
  name: 'FileDnsZone'
  params: {
   privateDNSZoneName: privateStorageFileDnsZoneName
  }
}

module storageFileDnsZoneGroup 'modules/network/privatednszonegroup.bicep' = {
  name: 'FileDnsZoneGroup'
  params: {
   privateEndpointName: privateEndpointStorageFileName
   privateDNSZoneId: storageFileDnsZone.outputs.privateDNSZoneId
  }
}


module storageBlobPE 'modules/network/privateendpoint.bicep'={
  name: 'storageBlobPE'
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
}

module storageBlobDnsZone 'modules/network/privatednszone.bicep' = {
  name: 'BlobDnsZone'
  params: {
   privateDNSZoneName: privateStorageBlobDnsZoneName
  }
}

module storageBlobDnsZoneGroup 'modules/network/privatednszonegroup.bicep' = {
  name: 'BlobDnsZoneGroup'
  params: {
   privateEndpointName: privateEndpointStorageBlobName
   privateDNSZoneId: storageBlobDnsZone.outputs.privateDNSZoneId
  }
}



module storageTablePE 'modules/network/privateendpoint.bicep'={
  name: 'storageTablePE'
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
}

module storageTableDnsZone 'modules/network/privatednszone.bicep' = {
  name: 'TableDnsZone'
  params: {
   privateDNSZoneName: privateStorageTableDnsZoneName
  }
}

module storageTableDnsZoneGroup 'modules/network/privatednszonegroup.bicep' = {
  name: 'TableDnsZoneGroup'
  params: {
   privateEndpointName: privateEndpointStorageTableName
   privateDNSZoneId: storageTableDnsZone.outputs.privateDNSZoneId
  }
}


module storagequeuePE 'modules/network/privateendpoint.bicep'={
  name: 'storagequeuePE'
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
}

module storageQueueDnsZone 'modules/network/privatednszone.bicep' = {
  name: 'QueueDnsZone'
  params: {
   privateDNSZoneName: privateStorageQueueDnsZoneName
  }
}

module storageQueueDnsZoneGroup 'modules/network/privatednszonegroup.bicep' = {
  name: 'QueueDnsZoneGroup'
  params: {
   privateEndpointName: privateEndpointStorageQueueName
   privateDNSZoneId: storageQueueDnsZone.outputs.privateDNSZoneId
  }
}
