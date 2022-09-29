@description('The name of the service.')
param serviceName string = 'vsantana-fhir'

@description('Location of Azure API for FHIR')
@allowed([
  'ukwest'
  'northcentralus'
  'westus2'
  'australiaeast'
  'southeastasia'
  'uksouth'
  'eastus'
  'westeurope'
  'southcentralus'
  'eastus2'
  'northeurope'
  'westcentralus'
  'japaneast'
  'germanywestcentral'
  'canadacentral'
  'southafricanorth'
  'switzerlandnorth'
  'centralindia'
  'westus3'
  'swedencentral'
])


param location string

resource service 'Microsoft.HealthcareApis/services@2021-11-01' = {
  name: serviceName
  location: location
  kind: 'fhir-R4'
  properties: {
    authenticationConfiguration: {
      audience: 'https://${serviceName}.azurehealthcareapis.com'
      authority: uri(environment().authentication.loginEndpoint, subscription().tenantId)
    }
  }
}

resource fhirworkspace 'Microsoft.HealthcareApis/workspaces@2022-06-01' = {
  name: serviceName
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource fhirservice 'Microsoft.HealthcareApis/workspaces/fhirservices@2022-06-01' = {
  name: '${serviceName}/default'
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource fhirmedtech 'Microsoft.HealthcareApis/workspaces/iotconnectors/fhirdestinations@2022-06-01' = {
  name: '${serviceName}/default/medtech'
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

// resource fhirmedtechconnector 'Microsoft.HealthcareApis/workspaces/iotconnectors@2022-06-01' = {
//   name: '${serviceName}/default'
//   location: location
//   properties: {
//     publicNetworkAccess: 'Disabled'
//   }
// }

// resource fhirmedtechdestinations 'Microsoft.HealthcareApis/workspaces/iotconnectors/fhirdestinations@' = {
//   name: '${serviceName}/default/medtech'
//   location: location
//   properties: {
//     publicNetworkAccess: 'Disabled'
//   }
// }