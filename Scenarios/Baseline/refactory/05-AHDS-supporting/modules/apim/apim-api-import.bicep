@description('The name of the API Management instance to deploy this API to.')
param serviceName string
param apiServiceURL string

resource apimService 'Microsoft.ApiManagement/service@2022-04-01-preview' existing = {
  name: serviceName
}

resource apiDefinition 'Microsoft.ApiManagement/service/apis@2022-04-01-preview' = {
  name: 'fhir-api'
  parent: apimService
  properties: {
    path: 'fhir'
    description: 'Azure Healthcare APIs'
    displayName: 'Microsoft'
    format: 'swagger-json'
    value: loadTextContent('./AHDS-Swagger.json')
    subscriptionRequired: true
    type: 'http'
    protocols: [ 'https' ]
    serviceUrl: apiServiceURL
  }
}
