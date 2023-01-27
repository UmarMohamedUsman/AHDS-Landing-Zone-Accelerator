//targetScope= 'subscription'
param keyvaultManagedIdentityObjectId string
param vaultName string
//param useraccessprincipalId string

resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: vaultName
}
resource keyvaultaccesspolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: '${vaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: keyvaultManagedIdentityObjectId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
        tenantId: subscription().tenantId
      }
      /*
      {
        objectId: useraccessprincipalId
        permissions: {
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
          keys: [
            'all'
          ]
          certificates: [
            'all'
          ]
        }
        tenantId: subscription().tenantId
      }
      */
    ]
  }
}
