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
var hubResourceGroupName = 'rg-hub-${resourceSuffix}'
var spokeResourceGroupName = 'rg-spoke-${resourceSuffix}'

var networkingHubResourceGroupName = hubResourceGroupName
var networkingSpokeResourceGroupName = spokeResourceGroupName
var sharedHubResourceGroupName = hubResourceGroupName
var sharedSpokeResourceGroupName = spokeResourceGroupName
var backendResourceGroupName = spokeResourceGroupName
var apimResourceGroupName = spokeResourceGroupName

// Resource Names
var apimName = 'apim-${resourceSuffix}'
var appGatewayName = 'appgw-${resourceSuffix}'

resource hubRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubResourceGroupName
  location: location
}

resource spokeRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: spokeResourceGroupName
  location: location
}

resource networkingHubRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: networkingHubResourceGroupName
}

resource networkingSpokeRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: networkingSpokeResourceGroupName
}

resource backendRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: backendResourceGroupName
}

resource sharedHubRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: sharedHubResourceGroupName
}

resource sharedSpokeRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: sharedSpokeResourceGroupName
}

resource apimRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing =  {
  name: apimResourceGroupName
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
    hubVnetName: networkingHub.outputs.hubVnetName
  }
}

/*
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
*/

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
    peVnetId:networking.outputs.spokeVnetId
    peSubnetId: networking.outputs.privateEndpointSubnetid
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
module dnsZoneModule 'shared/apim-dnszones.bicep'  = {
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
