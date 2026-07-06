#Requires -Version 7.0
<#
.SYNOPSIS
    Local deployment helper for Bicep infrastructure templates.

.DESCRIPTION
    Validates and deploys Bicep templates to Azure from a local development machine.
    Supports targeting specific environments and running what-if analysis.

.PARAMETER Environment
    Target environment: dev, staging, or prod.

.PARAMETER Location
    Azure region for the deployment. Defaults to eastus2.

.PARAMETER WhatIf
    Run what-if analysis without deploying.

.PARAMETER ValidateOnly
    Only validate the template without deploying.

.EXAMPLE
    .\deploy.ps1 -Environment dev
    .\deploy.ps1 -Environment staging -WhatIf
    .\deploy.ps1 -Environment prod -ValidateOnly
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter()]
    [string]$Location = 'eastus2',

    [Parameter()]
    [switch]$WhatIf,

    [Parameter()]
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# Configuration
# ============================================================================

$templateFile = Join-Path $PSScriptRoot '..\infra\main.bicep'
$parametersFile = Join-Path $PSScriptRoot "..\infra\parameters\$Environment.bicepparam"
$deploymentName = "$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# ============================================================================
# Validation
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  IaC Pipeline - Bicep Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Environment : $Environment"
Write-Host "  Location    : $Location"
Write-Host "  Template    : $templateFile"
Write-Host "  Parameters  : $parametersFile"
Write-Host "  Deployment  : $deploymentName"
Write-Host "========================================`n" -ForegroundColor Cyan

# Check Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Check if logged in
$account = az account show 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to login to Azure."
        exit 1
    }
}

# Check template file exists
if (-not (Test-Path $templateFile)) {
    Write-Error "Template file not found: $templateFile"
    exit 1
}

# Check parameters file exists
if (-not (Test-Path $parametersFile)) {
    Write-Error "Parameters file not found: $parametersFile"
    exit 1
}

# Prompt for SQL password if not set
if (-not $env:SQL_ADMIN_PASSWORD) {
    $securePassword = Read-Host "Enter SQL Admin Password" -AsSecureString
    $env:SQL_ADMIN_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    )
}

# ============================================================================
# Lint
# ============================================================================

Write-Host "Step 1: Linting Bicep template..." -ForegroundColor Green
az bicep lint --file $templateFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "Bicep lint failed."
    exit 1
}
Write-Host "  Lint passed." -ForegroundColor Green

# ============================================================================
# Validate
# ============================================================================

Write-Host "`nStep 2: Validating deployment..." -ForegroundColor Green
az deployment sub validate `
    --location $Location `
    --template-file $templateFile `
    --parameters $parametersFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "Validation failed."
    exit 1
}
Write-Host "  Validation passed." -ForegroundColor Green

if ($ValidateOnly) {
    Write-Host "`nValidation complete. Exiting (ValidateOnly mode)." -ForegroundColor Cyan
    exit 0
}

# ============================================================================
# What-If
# ============================================================================

Write-Host "`nStep 3: Running What-If analysis..." -ForegroundColor Green
az deployment sub what-if `
    --location $Location `
    --template-file $templateFile `
    --parameters $parametersFile `
    --result-format FullResourcePayloads

if ($WhatIf) {
    Write-Host "`nWhat-If complete. No changes were deployed." -ForegroundColor Cyan
    exit 0
}

# ============================================================================
# Deploy
# ============================================================================

if ($Environment -eq 'prod') {
    Write-Host "`n  WARNING: You are about to deploy to PRODUCTION!" -ForegroundColor Red
    $confirmation = Read-Host "  Type 'yes' to confirm"
    if ($confirmation -ne 'yes') {
        Write-Host "  Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`nStep 4: Deploying infrastructure..." -ForegroundColor Green
az deployment sub create `
    --location $Location `
    --template-file $templateFile `
    --parameters $parametersFile `
    --name $deploymentName

if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment failed."
    exit 1
}

# ============================================================================
# Output Results
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Deployment Successful!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nDeployment outputs:"
az deployment sub show `
    --name $deploymentName `
    --query properties.outputs `
    --output table

Write-Host "`nDone." -ForegroundColor Green
