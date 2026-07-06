using '../main.bicep'

param environment = 'staging'
param location = 'eastus2'
param projectName = 'iacpipeline'
param sqlAdminLogin = 'sqladmin'
param sqlAdminPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD', '')

param appServicePlanSku = {
  name: 'S1'
  tier: 'Standard'
  capacity: 2
}

param sqlDatabaseSku = {
  name: 'S1'
  tier: 'Standard'
  maxSizeBytes: 268435456000 // 250 GB
}

param tags = {
  costCenter: 'staging'
}
