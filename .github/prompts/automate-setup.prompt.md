---
agent: agent
description: This prompt is used to automate as much as possible, the setup of the Azure Governance Visualizer Accelerator.
model: Claude Haiku 4.5 (copilot)
---

# Automated Setup for Azure Governance Visualizer Accelerator

This prompt automates the deployment of the Azure Governance Visualizer Accelerator based on the instructions in the repository's README.md file.

## Prerequisites

Before running this automation, ensure you have:

1. **Azure CLI** - For Azure authentication and management
2. **PowerShell** - For script execution
3. **GitHub CLI** - For repository and secrets management
4. **AzAPICall PowerShell Module** - For Azure API interactions
5. **Azure MCP Server** - Enable all tools for Azure resource operations
6. **GitHub MCP Server** - Enable all tools for repository management

## Automated Setup Steps

### Step 1: Azure Authentication
Prompt user to log into Azure tenant and select the target subscription.

```powershell
Connect-AzAccount
Get-AzSubscription | Format-Table Name, Id, State
Select-AzSubscription -SubscriptionId "<selected-subscription-id>"
```

### Step 2: Azure Deployment Region
Prompt user for the Azure deployment region.
- Examples: `eastus2`, `centralus`, `westus2`, `northeurope`

### Step 3: App Registration Name
Prompt user for the app registration/service principal name.
- Default suggestion: `azgovviz-accelerator-01`

### Step 4: Create AzGovViz Service Principal
Create the app registration that will run Azure Governance Visualizer.

```powershell
$AzGovVizAppName = "azgovviz-accelerator-01"
# Create app registration with required permissions
```

### Step 5: Set API Permissions
Configure Microsoft Graph API permissions:
- `Application.Read.All`
- `Group.Read.All`
- `User.Read.All`
- `PrivilegedAccess.Read.AzureResources`

Grant admin consent for these permissions.

### Step 6: Generate Random String
Generate a unique identifier for resource naming.

```powershell
$resourceRandomString = (New-Guid).Guid.Substring(0,8)
```

### Step 7: Create Web App Authentication App (CRITICAL)
**THIS STEP MUST BE COMPLETED BEFORE RUNNING WORKFLOWS**

```powershell
$WebApplicationAppName = "azgovviz-web-auth-$resourceRandomString"
# Create app registration with redirect URIs and client secret
```

Verify the app was created successfully before proceeding.

### Step 8: Configure Federated Credentials
Automatically retrieve GitHub org and repo from git remote:

```powershell
$gitRemoteUrl = git remote get-url origin
$gitHubOrg = $gitRemoteUrl -replace '.*[:/]([^/]+)/[^/]+$', '$1'
$gitHubRepo = $gitRemoteUrl -replace '.*[:/]([^/]+)/([^/]+?)(?:\.git)?$', '$2'
$gitHubBranch = "main"
```

### Step 9: Management Group Selection (CRITICAL)
**Use management group IDs, NOT display names**

List all management groups and prompt user to select:
- IDs are short identifiers like: `alz`, `corp`, `mgmt`, `platform`
- NOT display names like: "Azure Landing Zones", "Corporate Management"

```powershell
Get-AzManagementGroup | Format-Table Name, DisplayName
```

### Step 10: Grant Reader Role
Assign Reader RBAC role to the service principal on the target management group.

```powershell
New-AzRoleAssignment -ApplicationId $AzGovVizAppId -RoleDefinitionName "Reader" -Scope "/providers/Microsoft.Management/managementGroups/$managementGroupId"
```

### Step 11: Generate Web App Name
Create unique names for Azure resources:

```powershell
$webAppName = "azgovviz-web-$resourceRandomString"
```

### Step 12: Create Resource Group
Create the resource group for the Azure Web App:

```powershell
$resourceGroupName = "rg-azgovviz-$resourceRandomString"
New-AzResourceGroup -Name $resourceGroupName -Location $location
```

### Step 13: Assign RBAC Roles to Service Principal
Assign Website Contributor and Web Plan Contributor roles:

```powershell
New-AzRoleAssignment -ApplicationId $AzGovVizAppId -RoleDefinitionName "Website Contributor" -ResourceGroupName $resourceGroupName
New-AzRoleAssignment -ApplicationId $AzGovVizAppId -RoleDefinitionName "Web Plan Contributor" -ResourceGroupName $resourceGroupName
```

### Step 14: Assign RBAC Roles to Current User
Enable portal access for the interactive user:

```powershell
$currentUser = (Get-AzContext).Account.Id
New-AzRoleAssignment -SignInName $currentUser -RoleDefinitionName "Website Contributor" -ResourceGroupName $resourceGroupName
New-AzRoleAssignment -SignInName $currentUser -RoleDefinitionName "Web Plan Contributor" -ResourceGroupName $resourceGroupName
```

### Step 15: Create GitHub Secrets (CRITICAL)
**VERIFY CORRECT REPOSITORY BEFORE SETTING SECRETS**

```powershell
# Verify repository
gh repo view

# Set secrets with explicit repo path
gh secret set CLIENT_ID -b $AzGovVizAppId --repo <org>/Azure-Governance-Visualizer-Accelerator
gh secret set ENTRA_CLIENT_ID -b $webAppClientId --repo <org>/Azure-Governance-Visualizer-Accelerator
gh secret set ENTRA_CLIENT_SECRET -b $webAppClientSecret --repo <org>/Azure-Governance-Visualizer-Accelerator
gh secret set SUBSCRIPTION_ID -b $subscriptionId --repo <org>/Azure-Governance-Visualizer-Accelerator
gh secret set TENANT_ID -b $tenantId --repo <org>/Azure-Governance-Visualizer-Accelerator
gh secret set MANAGEMENT_GROUP_ID -b $managementGroupId --repo <org>/Azure-Governance-Visualizer-Accelerator
```

### Step 16: Create GitHub Variables

```powershell
gh variable set RESOURCE_GROUP_NAME -b $resourceGroupName --repo <org>/Azure-Governance-Visualizer-Accelerator
gh variable set WEB_APP_NAME -b $webAppName --repo <org>/Azure-Governance-Visualizer-Accelerator
```

### Step 17: Verification Step (CRITICAL)
Verify all secrets and variables before running workflows:

```powershell
gh secret list --repo <org>/Azure-Governance-Visualizer-Accelerator
gh variable list --repo <org>/Azure-Governance-Visualizer-Accelerator
```

Expected output:
- 6 secrets: CLIENT_ID, ENTRA_CLIENT_ID, ENTRA_CLIENT_SECRET, SUBSCRIPTION_ID, TENANT_ID, MANAGEMENT_GROUP_ID
- 2 variables: RESOURCE_GROUP_NAME, WEB_APP_NAME

### Step 18: Configure GitHub Actions Permissions
Enable workflow permissions:

```powershell
gh api -X PUT /repos/<org>/Azure-Governance-Visualizer-Accelerator/actions/permissions/workflow -F can_approve_pull_request_reviews=true
```

### Step 19: Deploy Workflows
Run workflows in the correct order:

1. **DeployAzGovVizAccelerator** - Deploy Web App and configure auth
2. **SyncAzGovViz** - (Triggered automatically) Sync latest code
3. **DeployAzGovViz** - Deploy and publish AzGovViz

```powershell
gh workflow run DeployAzGovVizAccelerator.yml --repo <org>/Azure-Governance-Visualizer-Accelerator
# Wait for completion and SyncAzGovViz to finish
gh workflow run DeployAzGovViz.yml --repo <org>/Azure-Governance-Visualizer-Accelerator
```

### Step 20: Summary and Next Steps
After deployment completes:

1. Access the Web App via Azure Portal
2. Verify authentication works correctly
3. Review the generated governance visualization
4. Configure optional parameters in the DeployAzGovViz workflow
5. Enable scheduled runs if desired

### Step 21: User Confirmation
Prompt user to review and confirm before proceeding with next steps.

## Critical Reminders

- **Do NOT proceed past Step 7** unless the web app auth app is confirmed created
- **Do NOT set GitHub secrets** until confirming the correct repository (Step 15)
- **Always use management group IDs** (not display names) for MANAGEMENT_GROUP_ID
- **Always verify all 6 secrets + 2 variables** before running workflows (Step 17)
- **Use full repo paths** in all gh CLI commands

## Tool Requirements

### Required Tools
- Azure CLI (`az`)
- PowerShell (`pwsh`)
- GitHub CLI (`gh`)
- AzAPICall PowerShell module

### MCP Servers
Enable all tools for:
- **Azure MCP Server** - Azure resource management
- **GitHub MCP Server** - Repository, secrets, workflow management
