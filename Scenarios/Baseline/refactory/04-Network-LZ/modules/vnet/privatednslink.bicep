param privateDnsZoneName string
param vnetId string
param linkName string = ''

var linkFullName = linkName == '' ? '${privateDnsZoneName}/${privateDnsZoneName}-link-hub' : '${privateDnsZoneName}/${privateDnsZoneName}-${linkName}'

resource akshublink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: linkFullName
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}
