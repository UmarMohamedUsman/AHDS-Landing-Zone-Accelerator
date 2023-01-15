targetScope = 'subscription'
param location string = deployment().location
param rgHubName string
resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  location: location
  name: rgHubName
}
output rgId string = rg.id
output rgHubName string = rg.name
