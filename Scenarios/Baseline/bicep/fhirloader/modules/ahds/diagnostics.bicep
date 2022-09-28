param fhirservicename string
param laWorkspace string

resource FHIR 'Microsoft.HealthcareApis/workspaces/fhirservices@2021-11-01' existing = {
  name: fhirservicename
}

resource logs 'Microsoft.Insights/components@2020-02-02' existing = {
  name: laWorkspace
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '{$fhirservicename}-diag'
  scope: FHIR
  properties: {
    logAnalyticsDestinationType: 'null'
    logs: [
      {
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true
        }
      }
    ]
    metrics: [
      {
        enabled: false
        
      }
    ]
    workspaceId: logs.id
  }
}
