using '../main.bicep'

param environment = 'dev'
param location = 'southeastasia'
param projectName = 'iacpipeline'
param sqlAdminLogin = 'sqladmin'
param sqlAdminPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD', '')

param appServicePlanSku = {
  name: 'B1'
  tier: 'Basic'
  capacity: 1
}

param sqlDatabaseSku = {
  name: 'Basic'
  tier: 'Basic'
  maxSizeBytes: 2147483648 // 2 GB
}

param tags = {
  costCenter: 'development'
}
