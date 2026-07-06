using '../main.bicep'

param environment = 'prod'
param location = 'eastus2'
param projectName = 'iacpipeline'
param sqlAdminLogin = 'sqladmin'
param sqlAdminPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD', '')

param appServicePlanSku = {
  name: 'P1v3'
  tier: 'PremiumV3'
  capacity: 3
}

param sqlDatabaseSku = {
  name: 'S3'
  tier: 'Standard'
  maxSizeBytes: 268435456000 // 250 GB
}

param tags = {
  costCenter: 'production'
  compliance: 'required'
}
