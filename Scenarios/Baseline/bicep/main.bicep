targetScope='subscription'

// Parameters
@description('A short name for the workload being deployed alphanumberic only')
@maxLength(8)
param workloadName string

@description('The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'dr'
])
param environment string

@description('The user name to be used as the Administrator for all VMs created by this deployment')
param vmUsername string

@description('The password for the Administrator user for all VMs created by this deployment')
param vmPassword string

@description('The CI/CD platform to be used, and for which an agent will be configured for the ASE deployment. Specify \'none\' if no agent needed')
@allowed([
  'github'
  'azuredevops'
  'none'
])
param CICDAgentType string

@description('The Azure DevOps or GitHub account name to be used when configuring the CI/CD agent, in the format https://dev.azure.com/ORGNAME OR github.com/ORGUSERNAME OR none')
param accountName string

@description('The Azure DevOps or GitHub personal access token (PAT) used to setup the CI/CD agent')
@secure()
param personalAccessToken string

@description('The FQDN for the Application Gateway. Example - api.contoso.com.')
param appGatewayFqdn string

@description('The password for the TLS certificate for the Application Gateway.  The pfx file needs to be copied to deployment/bicep/gateway/certs/appgw.pfx')
@secure()
param certificatePassword string

@description('Set to selfsigned if self signed certificates should be used for the Application Gateway. Set to custom and copy the pfx file to deployment/bicep/gateway/certs/appgw.pfx if custom certificates are to be used')
param appGatewayCertType string

param location string = deployment().location

// Variables
var resourceSuffix = '${workloadName}-${environment}-${location}-001'
var networkingHubResourceGroupName = 'rg-networking-hub-${resourceSuffix}'
var networkingSpokeResourceGroupName = 'rg-networking-spoke-${resourceSuffix}'
var sharedHubResourceGroupName = 'rg-shared-hub-${resourceSuffix}'
var sharedSpokeResourceGroupName = 'rg-shared-spoke-${resourceSuffix}'


var backendResourceGroupName = 'rg-backend-${resourceSuffix}'

var apimResourceGroupName = 'rg-apim-${resourceSuffix}'

// Resource Names
var apimName = 'apim-${resourceSuffix}'
var appGatewayName = 'appgw-${resourceSuffix}'


resource networkingHubRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkingHubResourceGroupName
  location: location
}

resource networkingSpokeRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkingSpokeResourceGroupName
  location: location
}

resource backendRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: backendResourceGroupName
  location: location
}

resource sharedHubRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: sharedHubResourceGroupName
  location: location
}

resource sharedSpokeRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: sharedSpokeResourceGroupName
  location: location
}

resource apimRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: apimResourceGroupName
  location: location
}

module networkingHub './networking/networking-hub.bicep' = {
  name: 'networkingresources'
  scope: resourceGroup(networkingHubRG.name)
  params: {
    workloadName: workloadName
    deploymentEnvironment: environment
    location: location
  }
}

module networking './networking/networking-spoke.bicep' = {
  dependsOn: [
    networkingHub
  ]
  name: 'networkingresources'
  scope: resourceGroup(networkingSpokeRG.name)
  params: {
    workloadName: workloadName
    deploymentEnvironment: environment
    location: location
    hubVnetId: networkingHub.outputs.hubVnetId
  }
}

module backend './backend/backend.bicep' = {
  name: 'backendresources'
  scope: resourceGroup(backendRG.name)
  params: {
    workloadName: workloadName
    environment: environment
    location: location    
    vnetName: networking.outputs.spokeVnetName
    vnetRG: networkingSpokeRG.name
    backendSubnetId: networking.outputs.backEndSubnetid
    privateEndpointSubnetid: networking.outputs.privateEndpointSubnetid
  }
}

var jumpboxSubnetId= networkingHub.outputs.jumpBoxSubnetid
var CICDAgentSubnetId = networking.outputs.CICDAgentSubnetId

module sharedHub './shared/shared-hub.bicep' = {
  dependsOn: [
    networkingHub
  ]
  name: 'sharedHubResources'
  scope: resourceGroup(sharedHubRG.name)
  params: {
    environment: environment
    jumpboxSubnetId: jumpboxSubnetId
    location: location
    resourceGroupName: sharedHubRG.name
    vmPassword: vmPassword
    vmUsername: vmUsername
  }
}

module shared './shared/shared-spoke.bicep' = {
  dependsOn: [
    networking
  ]
  name: 'sharedSpokeResources'
  scope: resourceGroup(sharedSpokeRG.name)
  params: {
    accountName: accountName
    CICDAgentSubnetId: CICDAgentSubnetId
    CICDAgentType: CICDAgentType
    environment: environment
    location: location
    personalAccessToken: personalAccessToken
    resourceGroupName: sharedSpokeRG.name
    resourceSuffix: resourceSuffix
    vmPassword: vmPassword
    vmUsername: vmUsername
  }
}

module apimModule 'apim/apim.bicep'  = {
  name: 'apimDeploy'
  scope: resourceGroup(apimRG.name)
  params: {
    apimName: apimName
    apimSubnetId: networking.outputs.apimSubnetid
    location: location
    appInsightsName: shared.outputs.appInsightsName
    appInsightsId: shared.outputs.appInsightsId
    appInsightsInstrumentationKey: shared.outputs.appInsightsInstrumentationKey
  }
}

//Creation of private DNS zones
module dnsZoneModule 'shared/dnszone.bicep'  = {
  name: 'apimDnsZoneDeploy'
  scope: resourceGroup(sharedSpokeRG.name)
  dependsOn: [
    apimModule
  ]
  params: {
    vnetName: networking.outputs.spokeVnetName
    vnetRG: networkingSpokeRG.name
    apimName: apimName
    apimRG: apimRG.name
  }
}

module appgwModule 'gateway/appgw.bicep' = {
  name: 'appgwDeploy'
  scope: resourceGroup(apimRG.name)
  dependsOn: [
    apimModule
    dnsZoneModule
  ]
  params: {
    appGatewayName:                 appGatewayName
    appGatewayFQDN:                 appGatewayFqdn
    location:                       location
    appGatewaySubnetId:             networking.outputs.appGatewaySubnetid
    primaryBackendEndFQDN:          '${apimName}.azure-api.net'
    keyVaultName:                   shared.outputs.keyVaultName
    keyVaultResourceGroupName:      sharedSpokeRG.name
    appGatewayCertType:             appGatewayCertType
    certPassword:                   certificatePassword
  }
}
