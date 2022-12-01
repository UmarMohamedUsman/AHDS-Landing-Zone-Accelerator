param functionAppName string
param location string
param hostingPlanName string
param appInsightsInstrumentationKey string
param functionContentShareName string
param storageAccountName string
param fnIdentityId string
param VNetIntegrationSubnetID string
param kvname string

var runtime  = 'dotnet'
var repourl  = 'https://github.com/microsoft/fhir-loader'

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: hostingPlanName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
 //scope: resourceGroup(subscription().subscriptionId, RG)
}


resource functionContentShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name: '${storageAccount.name}/default/${functionContentShareName}'
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities:{
      '${fnIdentityId}' : {}
    }
  }
  properties: {
    reserved: false
    serverFarmId: hostingPlan.id
    virtualNetworkSubnetId: VNetIntegrationSubnetID
    keyVaultReferenceIdentity: fnIdentityId
    siteConfig: {
      vnetRouteAllEnabled: true
      functionsRuntimeScaleMonitoringEnabled: true
      http20Enabled: false
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
         // value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: runtime
        }
        {
          name: 'AzureWebJobs.ImportBundleBlobTrigger.Disabled'
          value: '0'
        }
        {
          name: 'AzureWebJobs.ImportBundleEventGrid.Disabled'
          value: '1'
        }
        {
          name: 'FBI-TRANSFORMBUNDLES'
          value: 'true'
        }
        {
          name: 'FBI-POOLEDCON-MAXCONNECTIONS'
          value: '20'
        }

        {
          name: 'FBI-STORAGEACCT'
          value: '@Microsoft.KeyVault(VaultName=${kvname};SecretName=FBI-STORAGEACCT)'
        }
        {
          name: 'FS-URL'
          value: '@Microsoft.KeyVault(VaultName=${kvname};SecretName=FS-URL)'
        }
        {
          name: 'FS-TENANT-NAME'
          value: '@Microsoft.KeyVault(VaultName=${kvname};SecretName=FS-TENANT-NAME)'
        }
        {
          name: 'FS-RESOURCE'
          value: '@Microsoft.KeyVault(VaultName=${kvname};SecretName=FS-RESOURCE)'
        }

        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: functionContentShareName
        }
        {
        name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
        value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'

    }

    httpsOnly: true
    redundancyMode: 'None'
  }
}

resource functiondeploy 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  name: 'web'
  kind: 'sourcecontrols'
  parent: functionApp
  properties: {
    branch: 'main'
    isManualIntegration: true
    repoUrl: repourl
  }
}

output fnappidentity string = functionApp.identity.principalId
output fnappid string = functionApp.id
