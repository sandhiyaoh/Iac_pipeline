targetScope = 'subscription'

// ============================================================================
// Main Orchestration Template
// Deploys a complete application environment with App Service, SQL, Key Vault,
// and monitoring resources.
// ============================================================================

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Azure region for all resources')
param location string

@description('Base name for the project (used in resource naming)')
@minLength(3)
@maxLength(11)
param projectName string

@description('SQL Server administrator login')
param sqlAdminLogin string

@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string

@description('App Service Plan SKU')
param appServicePlanSku object

@description('SQL Database SKU')
param sqlDatabaseSku object

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// Variables
// ============================================================================

var resourceGroupName = 'rg-${projectName}-${environment}'
var defaultTags = union(tags, {
  environment: environment
  project: projectName
  managedBy: 'bicep'
  lastDeployed: utcNow('yyyy-MM-dd')
})

// ============================================================================
// Resource Group
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: defaultTags
}

// ============================================================================
// Module Deployments
// ============================================================================

module monitoring 'modules/monitoring.bicep' = {
  scope: rg
  name: 'monitoring-${uniqueString(rg.id)}'
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: defaultTags
  }
}

module keyVault 'modules/keyVault.bicep' = {
  scope: rg
  name: 'keyvault-${uniqueString(rg.id)}'
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: defaultTags
  }
}

module sqlDatabase 'modules/sqlDatabase.bicep' = {
  scope: rg
  name: 'sql-${uniqueString(rg.id)}'
  params: {
    location: location
    projectName: projectName
    environment: environment
    adminLogin: sqlAdminLogin
    adminPassword: sqlAdminPassword
    databaseSku: sqlDatabaseSku
    tags: defaultTags
  }
}

module appService 'modules/appService.bicep' = {
  scope: rg
  name: 'appservice-${uniqueString(rg.id)}'
  params: {
    location: location
    projectName: projectName
    environment: environment
    appServicePlanSku: appServicePlanSku
    appInsightsInstrumentationKey: monitoring.outputs.instrumentationKey
    appInsightsConnectionString: monitoring.outputs.connectionString
    keyVaultUri: keyVault.outputs.vaultUri
    tags: defaultTags
  }
}

// ============================================================================
// Outputs
// ============================================================================

output resourceGroupName string = rg.name
output appServiceName string = appService.outputs.appServiceName
output appServiceDefaultHostname string = appService.outputs.defaultHostname
output sqlServerFqdn string = sqlDatabase.outputs.serverFqdn
output keyVaultName string = keyVault.outputs.vaultName
output appInsightsName string = monitoring.outputs.appInsightsName
