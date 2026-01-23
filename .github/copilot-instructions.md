# Copilot Instructions for Azure Governance Visualizer Accelerator

This document provides guidance for GitHub Copilot when working with the Azure Governance Visualizer Accelerator repository.

## Repository Overview

This repository is the **Azure Governance Visualizer (AzGovViz) Accelerator** - a deployment accelerator for the [Azure Governance Visualizer](https://github.com/Azure/Azure-Governance-Visualizer) tool. It automates deployment to Azure using GitHub Actions, Bicep templates, and PowerShell scripts.

## Technology Stack

- **Infrastructure as Code:** Bicep templates (`.bicep` files)
- **Scripting:** PowerShell (`.ps1` files)
- **CI/CD:** GitHub Actions workflows (`.yml` files)
- **Cloud Platform:** Microsoft Azure
- **Identity:** Microsoft Entra ID (Azure AD)
- **Authentication:** OpenID Connect (OIDC) with federated credentials

## Code Standards and Conventions

### PowerShell Scripts

- Use `AzAPICall` module for Azure API interactions
- Follow PowerShell naming conventions (Verb-Noun pattern)
- Include parameter validation and error handling
- Use splatting for cmdlets with many parameters
- Prefer `Write-Host` for user feedback during script execution

```powershell
# Example pattern from this repository
$parameters4AzAPICallModule = @{
    #SubscriptionId4AzContext = $null
    #DebugAzAPICall = $true
}
$azAPICallConf = initAzAPICall @parameters4AzAPICallModule
```

### Bicep Templates

- Location: `bicep/` directory
- Use parameter files (`.parameters.json`) for configurable values
- Follow Azure naming conventions for resources
- Include comments for complex configurations

### GitHub Actions Workflows

- Location: `.github/workflows/`
- Use GitHub secrets for sensitive values (CLIENT_ID, TENANT_ID, etc.)
- Use GitHub variables for non-sensitive configuration (RESOURCE_GROUP_NAME, WEB_APP_NAME)
- Implement federated credentials for Azure authentication (no stored secrets)
- Follow workflow naming pattern: `DeployAzGovViz*.yml`, `Sync*.yml`

## Required Secrets and Variables

### GitHub Secrets (6 required)

| Secret | Description |
|--------|-------------|
| `CLIENT_ID` | App registration ID for running AzGovViz |
| `ENTRA_CLIENT_ID` | App registration ID for web app authentication |
| `ENTRA_CLIENT_SECRET` | Client secret for web app authentication |
| `SUBSCRIPTION_ID` | Target Azure subscription ID |
| `TENANT_ID` | Microsoft Entra tenant ID |
| `MANAGEMENT_GROUP_ID` | Target management group ID (use ID, not display name) |

### GitHub Variables (2 required)

| Variable | Description |
|----------|-------------|
| `RESOURCE_GROUP_NAME` | Resource group for the Azure Web App |
| `WEB_APP_NAME` | Globally unique name for the Azure Web App |

## Deployment Process

The deployment follows a specific workflow order:

1. **DeployAzGovVizAccelerator** - Deploys Azure Web App and configures authentication
2. **SyncAzGovViz** - Syncs latest AzGovViz code (triggered automatically)
3. **DeployAzGovViz** - Deploys and publishes AzGovViz to the Web App

## Key Azure Resources

- **App Registration (Service Principal):** Runs AzGovViz with Reader permissions
- **App Registration (Web Auth):** Handles user authentication to the Web App
- **Resource Group:** Contains the Azure Web App
- **Azure Web App:** Hosts the governance visualizer output

## API Permissions Required

The service principal running AzGovViz needs these Microsoft Graph permissions:

- `Application.Read.All`
- `Group.Read.All`
- `User.Read.All`
- `PrivilegedAccess.Read.AzureResources`

## RBAC Roles Required

- **Reader** on the target management group (for scanning)
- **Website Contributor** on the resource group
- **Web Plan Contributor** on the resource group

## Documentation Style

- Use Markdown for documentation
- Include both portal-based (🖱️) and PowerShell-based (⌨️) instructions
- Use tables for secrets, variables, and configuration options
- Include screenshots in `media/` directory
- Use Mermaid diagrams for process flows

## File Naming Conventions

- PowerShell scripts: `camelCase.ps1` for functions, `PascalCase.ps1` for main scripts
- Bicep: `camelCase.bicep` and `camelCase.parameters.json`
- Workflows: `PascalCase.yml`
- Media: Descriptive names with underscores (e.g., `azure_web_app.png`)

## Error Handling Patterns

When working with Azure APIs:

```powershell
do {
    Write-Host "Waiting for the resource to get created..."
    Start-Sleep -seconds 20
    $result = AzAPICall -method GET -uri $uri -AzAPICallConfiguration $azAPICallConf
} until ($null -ne $result)
Write-Host "Resource created successfully."
```

## Security Best Practices

1. Never commit secrets to the repository
2. Use federated credentials instead of client secrets for GitHub Actions
3. Follow least-privilege principle for RBAC assignments
4. Enable `groupMembershipClaims: SecurityGroup` for web app authentication
5. Use private repositories for deployment

## Common Troubleshooting

1. **Management Group ID vs Display Name:** Always use the ID (e.g., "alz"), not display name
2. **Federated Credentials:** Ensure org/repo/branch match exactly
3. **Web App Auth App:** Must be created before running deployment workflows
4. **Admin Consent:** Required for Microsoft Graph API permissions

## MCP Integration

When using GitHub Copilot with MCP servers:

- **Azure MCP Server:** For Azure resource operations
- **GitHub MCP Server:** For repository, secrets, and workflow management

Enable all tools for both MCP servers to maximize automation capabilities.
