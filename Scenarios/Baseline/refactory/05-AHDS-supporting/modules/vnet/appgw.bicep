param appgwname string
param subnetid string
param appgwpip string
param location string = resourceGroup().location
param appGwyAutoScale object
param appGatewayFQDN string = 'api.example.com'
param primaryBackendEndFQDN string
param appGatewayIdentityId string
var frontendPortNameHTTP = 'HTTP-80'
var frontendPortNameHTTPs = 'HTTPs-443'
var frontendIPConfigurationName = 'appGatewayFrontendIP'
var httplistenerName = 'httplistener'
var httpslistenerName = 'httpslistener'
var backendAddressPoolName = 'backend-add-pool'
var backendHttpSettingsCollectionName = 'backend-http-settings'
var backendHttpsSettingsCollectionName = 'backend-https-settings'
param keyVaultSecretId string
param availabilityZones array

resource appgw 'Microsoft.Network/applicationGateways@2021-02-01' = {
  name: appgwname
  location: location
  zones: !empty(availabilityZones) ? availabilityZones : null
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGatewayIdentityId}': {}
    }
  }
  properties: {
    autoscaleConfiguration: !empty(appGwyAutoScale) ? appGwyAutoScale : null
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: empty(appGwyAutoScale) ? 2 : null
    }
    gatewayIPConfigurations: [
      {
        name: 'appgw-ip-configuration'
        properties: {
          subnet: {
            id: subnetid
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendIPConfigurationName
        properties: {
          publicIPAddress: {
            id: appgwpip
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendPortNameHTTP
        properties: {
          port: 80
        }
      }
      {
        name: frontendPortNameHTTPs
        properties: {
          port: 443
        }
      }
    ]
    sslCertificates: [
      {
        name: appGatewayFQDN
        properties: {
          keyVaultSecretId:  keyVaultSecretId
        }
      }
    ]
    sslPolicy: {
      minProtocolVersion: 'TLSv1_2'
      policyType: 'Custom'
      cipherSuites: [
         'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256'
         'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384'
         'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
         'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
         'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256'
         'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384'
         'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256'
         'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384'
      ]
    }
    backendAddressPools: [
      {
        name: backendAddressPoolName
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: backendHttpSettingsCollectionName
        properties: {
          cookieBasedAffinity: 'Disabled'
          path: '/'
          port: 80
          protocol: 'Http'
          requestTimeout: 60
        }
      }
      {
        name: 'https'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          hostName: primaryBackendEndFQDN
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appgwname)}/probes/APIM'
          }
        }
      }
    ]
    httpListeners: [
      {
        name: httplistenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwname, frontendIPConfigurationName)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appgwname, frontendPortNameHTTP)
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      {
        name: httpslistenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwname, frontendIPConfigurationName)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appgwname, frontendPortNameHTTPs)
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appgwname, appGatewayFQDN)
          }
          hostnames: []
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'apim'
        properties:{
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appgwname, httpslistenerName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appgwname, backendAddressPoolName)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appgwname, backendHttpsSettingsCollectionName)
          }
        }
      }
    ]
  }
}

