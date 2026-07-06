// ============================================================================
// SQL Database Module
// Deploys Azure SQL Server and Database with security best practices.
// ============================================================================

@description('Azure region for resources')
param location string

@description('Project name for resource naming')
param projectName string

@description('Environment name')
param environment string

@description('SQL Server administrator login')
param adminLogin string

@secure()
@description('SQL Server administrator password')
param adminPassword string

@description('SQL Database SKU configuration')
param databaseSku object

@description('Tags to apply to resources')
param tags object

// ============================================================================
// Variables
// ============================================================================

var sqlServerName = 'sql-${projectName}-${environment}-${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = 'sqldb-${projectName}-${environment}'

// ============================================================================
// SQL Server
// ============================================================================

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: environment == 'prod' ? 'Disabled' : 'Enabled'
  }
}

// ============================================================================
// SQL Database
// ============================================================================

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: databaseSku.name
    tier: databaseSku.tier
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: databaseSku.maxSizeBytes
    zoneRedundant: environment == 'prod'
  }
}

// ============================================================================
// Firewall Rule - Allow Azure Services (non-prod only)
// ============================================================================

resource firewallRule 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = if (environment != 'prod') {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// ============================================================================
// Auditing Policy
// ============================================================================

resource auditingPolicy 'Microsoft.Sql/servers/auditingSettings@2023-08-01-preview' = {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    retentionDays: environment == 'prod' ? 90 : 30
    isAzureMonitorTargetEnabled: true
  }
}

// ============================================================================
// Outputs
// ============================================================================

output serverName string = sqlServer.name
output serverFqdn string = sqlServer.properties.fullyQualifiedDomainName
output databaseName string = sqlDatabase.name
