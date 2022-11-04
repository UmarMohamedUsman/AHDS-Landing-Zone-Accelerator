param nameSufix string
param location string = resourceGroup().location
param name string = '${nameSufix}${uniqueString('keyvault-VM',utcNow('u'))}'

@secure()
param secrets object = {}

//var secretList = !empty(secrets) ? secrets.secureList : {}

resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'premium'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
    accessPolicies: []
  }
}

resource secretuser 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: secrets.user.name
  parent: keyvault
  properties: {
    value: secrets.user.value
  }
}

resource secretpassword 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: secrets.password.name
  parent: keyvault
  properties: {
    value: secrets.password.value
  }
}
