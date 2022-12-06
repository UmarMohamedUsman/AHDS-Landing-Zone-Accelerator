param fhirName string
param workspaceName string
param location string = resourceGroup().location

var tenantId = subscription().tenantId
var fhirservicename = '${workspaceName}/${fhirName}'
var loginURL = environment().authentication.loginEndpoint
var authority = '${loginURL}${tenantId}'
var audience = 'https://${workspaceName}-${fhirName}.fhir.azurehealthcareapis.com'


resource Workspace 'Microsoft.HealthcareApis/workspaces@2022-06-01' = {
  name: workspaceName
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}
/*
resource exampleExistingWorkspace 'Microsoft.HealthcareApis/workspaces@2021-06-01-preview' existing = {
  name: workspaceName
}
*/

resource FHIR 'Microsoft.HealthcareApis/workspaces/fhirservices@2021-11-01' = {
  name: fhirservicename
  location: location
  kind: 'fhir-R4'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    accessPolicies: []
    authenticationConfiguration: {
      authority: authority
      audience: audience
      smartProxyEnabled: false
    }
    publicNetworkAccess: 'Disabled'
    }
    dependsOn: [
      Workspace
    ]
}

output fhirServiceURL string = audience
output fhirID string = FHIR.id
