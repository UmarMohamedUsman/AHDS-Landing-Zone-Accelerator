param privateDNSZoneName string
param vnetid string

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSZoneName
  location: 'global'
  resource storageBlobDnsZoneLink 'virtualNetworkLinks' = {
    name: '${privateDNSZone.name}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnetid
      }
    }
  }
}

output privateDNSZoneName string = privateDNSZone.name
output privateDNSZoneId string = privateDNSZone.id
