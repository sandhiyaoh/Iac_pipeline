# Infrastructure as Code Pipeline with Bicep

This project demonstrates a complete IaC pipeline using Azure Bicep for infrastructure provisioning with CI/CD automation.

## Project Structure

```
├── .github/
│   └── workflows/
│       └── deploy-infrastructure.yml   # GitHub Actions CI/CD pipeline
├── infra/
│   ├── main.bicep                      # Main orchestration template
│   ├── modules/
│   │   ├── appService.bicep            # App Service module
│   │   ├── sqlDatabase.bicep           # SQL Database module
│   │   ├── keyVault.bicep              # Key Vault module
│   │   └── monitoring.bicep            # Application Insights module
│   └── parameters/
│       ├── dev.bicepparam              # Dev environment parameters
│       ├── staging.bicepparam          # Staging environment parameters
│       └── prod.bicepparam             # Production environment parameters
├── scripts/
│   └── deploy.ps1                      # Local deployment helper script
├── bicepconfig.json                    # Bicep linter configuration
└── README.md
```

## Architecture

The pipeline deploys the following Azure resources:
- **App Service Plan + Web App** — Hosts the application
- **Azure SQL Database** — Relational data store
- **Key Vault** — Secrets management
- **Application Insights** — Monitoring and diagnostics

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (v2.20+)
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) (included with Azure CLI v2.20+)
- An Azure subscription
- A GitHub repository with configured secrets (for CI/CD)

## Getting Started

### 1. Configure Azure Credentials

Create a service principal and add it as a GitHub secret:

```bash
az ad sp create-for-rbac --name "iac-pipeline-sp" --role contributor \
  --scopes /subscriptions/{subscription-id} --sdk-auth
```

Add the JSON output as a GitHub secret named `AZURE_CREDENTIALS`.

Also add these secrets:
- `AZURE_SUBSCRIPTION_ID` — Your Azure subscription ID
- `SQL_ADMIN_PASSWORD` — Password for the SQL admin user

### 2. Local Deployment

```powershell
# Login to Azure
az login

# Deploy to dev environment
.\scripts\deploy.ps1 -Environment dev -Location "eastus2"
```

### 3. CI/CD Pipeline

The GitHub Actions workflow automatically:
1. **Validates** Bicep templates (lint + build)
2. **What-If** previews infrastructure changes
3. **Deploys** to dev on push to `main`
4. **Deploys** to staging/prod with manual approval gates

## Environments

| Environment | Trigger        | Approval Required |
|-------------|----------------|-------------------|
| Dev         | Push to `main` | No                |
| Staging     | Manual         | Yes               |
| Production  | Manual         | Yes               |

## Linting & Validation

```bash
# Validate Bicep syntax
az bicep build --file infra/main.bicep

# Preview changes (what-if)
az deployment sub what-if --location eastus2 \
  --template-file infra/main.bicep \
  --parameters infra/parameters/dev.bicepparam
```
