#!/usr/bin/env pwsh
# Azure Governance Visualizer Accelerator - Phase 2: Federated Credentials & GitHub Setup
# Steps 9-18: Configure federated credentials, RBAC, resource group, GitHub secrets, and deploy

# ===== PHASE 1 CONFIGURATION (HARDCODED) =====
$creds = @{
  AzGovVizAppId = "YOUR_SERVICE_PRINCIPAL_ID"  # Will be updated by user prompt
  AzGovVizAppObjectId = "YOUR_APP_OBJECT_ID"   # Will be updated by user prompt
  WebAppAppId = "YOUR_WEB_APP_APP_ID"
  WebAppAppObjectId = "YOUR_WEB_APP_OBJECT_ID"
  WebAppSecret = "YOUR_WEB_APP_SECRET"
  appName = "azgovviz-accelerator-01"
  webAppName = "azgovviz-web-cf0f6a7e"
  resourceGroupName = "rg-azgovviz-cf0f6a7e"
  region = "eastus2"
  subscriptionId = "976c53b8-965c-4f97-ab51-993195a8623c"
  tenantId = "54d665dd-30f1-45c5-a8d5-d6ffcdb518f9"
  managementGroupName = "Azure Landing Zones"
}

# ===== INTERACTIVE INPUT: GATHER GITHUB INFO =====
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Phase 2: Federated Credentials, RBAC, & GitHub Setup" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "PHASE 1 CONFIGURATION (from previous setup):" -ForegroundColor Yellow
Write-Host "├─ Service Principal:   $($creds.appName)" -ForegroundColor Gray
Write-Host "├─ Web App Name:        $($creds.webAppName)" -ForegroundColor Gray
Write-Host "├─ Resource Group:      $($creds.resourceGroupName)" -ForegroundColor Gray
Write-Host "├─ Subscription:        $($creds.subscriptionId)" -ForegroundColor Gray
Write-Host "├─ Tenant:              $($creds.tenantId)" -ForegroundColor Gray
Write-Host "└─ Management Group:    $($creds.managementGroupName)" -ForegroundColor Gray
Write-Host ""

# Get GitHub info interactively
Write-Host "REQUIRED: GitHub Configuration" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan
$gitHubOrg = Read-Host "Enter GitHub username or organization"
if ([string]::IsNullOrEmpty($gitHubOrg)) {
  Write-Host "ERROR: GitHub username/org cannot be empty" -ForegroundColor Red
  exit 1
}

$gitHubRepo = Read-Host "Enter GitHub repository name (default: Azure-Governance-Visualizer)" 
if ([string]::IsNullOrEmpty($gitHubRepo)) { $gitHubRepo = "Azure-Governance-Visualizer" }

$gitHubBranch = Read-Host "Enter GitHub branch (default: main)"
if ([string]::IsNullOrEmpty($gitHubBranch)) { $gitHubBranch = "main" }

Write-Host ""
Write-Host "CONFIRMATION:" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host "├─ GitHub Organization: $gitHubOrg" -ForegroundColor Yellow
Write-Host "├─ Repository:          $gitHubRepo" -ForegroundColor Yellow
Write-Host "└─ Branch:              $gitHubBranch" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Is this correct? (yes/no)"
if ($confirm -ne 'yes' -and $confirm -ne 'y') {
  Write-Host "Setup cancelled." -ForegroundColor Yellow
  exit 0
}

Write-Host ""
Write-Host "✓ Configuration confirmed. Proceeding with Phase 2..." -ForegroundColor Green
Write-Host ""

# IMPORTANT: User must provide Phase 1 credential values
Write-Host "REQUIRED: Enter Phase 1 Output Values" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host "(You should have these from the Phase 1 script execution)" -ForegroundColor Gray
Write-Host ""

$appId = Read-Host "Enter Service Principal Application ID (AzGovVizAppId)"
if ([string]::IsNullOrEmpty($appId)) {
  Write-Host "ERROR: Service Principal ID is required" -ForegroundColor Red
  exit 1
}
$creds.AzGovVizAppId = $appId

$appObjId = Read-Host "Enter Service Principal Object ID (AzGovVizAppObjectId)"
if ([string]::IsNullOrEmpty($appObjId)) {
  Write-Host "ERROR: Service Principal Object ID is required" -ForegroundColor Red
  exit 1
}
$creds.AzGovVizAppObjectId = $appObjId

$webAppId = Read-Host "Enter Web App Application ID (WebAppAppId)"
if ([string]::IsNullOrEmpty($webAppId)) {
  Write-Host "ERROR: Web App ID is required" -ForegroundColor Red
  exit 1
}
$creds.WebAppAppId = $webAppId

$webAppSecret = Read-Host "Enter Web App Client Secret (WebAppSecret)" -AsSecureString
$creds.WebAppSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemAlloc($webAppSecret))

Write-Host ""
Write-Host "✓ All Phase 1 credentials entered." -ForegroundColor Green
Write-Host ""

# Initialize AzAPICall
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 9: Configuring Federated Credentials" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

$azAPICallConf = initAzAPICall -SkipAzContextSubscriptionValidation $true
$apiEndPoint = $azAPICallConf['azAPIEndpointUrls'].MicrosoftGraph
$apiVersion = '/v1.0'

# Create federated credential
$gitHubRef = ":ref:refs/heads/$gitHubBranch"
$subject = "repo:$gitHubOrg/$gitHubRepo$gitHubRef"

$fedCredBody = @{
  audiences = @("api://AzureADTokenExchange")
  subject = $subject
  issuer = "https://token.actions.githubusercontent.com"
  name = "AzGovVizCreds-$gitHubBranch"
} | ConvertTo-Json -Depth 10

Write-Host "Creating federated credential for: repo:$gitHubOrg/$gitHubRepo (branch: $gitHubBranch)" -ForegroundColor Yellow

AzAPICall -method POST -body $fedCredBody `
  -uri "$apiEndPoint$apiVersion/applications/$($creds.AzGovVizAppObjectId)/federatedIdentityCredentials" `
  -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual' | Out-Null

Write-Host "✓ Federated credential created" -ForegroundColor Green

# ===== STEP 10-11: Grant RBAC on Management Group =====
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 10-11: Granting RBAC Permissions on Management Group" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Get management group ID
$mgName = $creds.managementGroupName
Write-Host "Resolving management group: $mgName" -ForegroundColor Yellow

# First try to get by display name
$managementGroups = az account management-group list --query "[].{id:id, displayName:displayName}" -o json | ConvertFrom-Json
$targetMG = $managementGroups | Where-Object { $_.displayName -eq $mgName } | Select-Object -First 1

if ($null -eq $targetMG) {
  Write-Host "ERROR: Management group '$mgName' not found!" -ForegroundColor Red
  Write-Host "Available groups:" -ForegroundColor Yellow
  $managementGroups | ForEach-Object { Write-Host "  - $($_.displayName) ($($_.id))" }
  
  # Prompt for manual selection
  $mgDisplayName = Read-Host "Enter management group display name"
  $targetMG = $managementGroups | Where-Object { $_.displayName -eq $mgDisplayName } | Select-Object -First 1
  
  if ($null -eq $targetMG) {
    Write-Host "Management group still not found. Exiting." -ForegroundColor Red
    exit 1
  }
}

$managementGroupId = $targetMG.id
Write-Host "✓ Management group resolved: $managementGroupId" -ForegroundColor Green

# Grant Reader role
Write-Host "Granting Reader role to $($creds.AzGovVizAppId)..." -ForegroundColor Yellow

New-AzRoleAssignment `
  -ApplicationId $creds.AzGovVizAppId `
  -RoleDefinitionName "Reader" `
  -Scope "/providers/Microsoft.Management/managementGroups/$managementGroupId" `
  -ErrorAction SilentlyContinue | Out-Null

Write-Host "✓ Reader role assigned on management group" -ForegroundColor Green

# ===== STEP 12-14: Create Resource Group and Assign Roles =====
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 12-14: Creating Resource Group & Assigning Roles" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Set subscription context
Write-Host "Setting subscription context: $($creds.subscriptionId)" -ForegroundColor Yellow
az account set --subscription $creds.subscriptionId

# Create resource group
$rgName = $creds.resourceGroupName
$region = $creds.region

Write-Host "Creating resource group: $rgName (Region: $region)" -ForegroundColor Yellow

az group create --name $rgName --location $region | Out-Null

Write-Host "✓ Resource group created" -ForegroundColor Green

# Assign roles to web app service principal (NOT the main app, but web app auth app)
Write-Host "Assigning Web App roles..." -ForegroundColor Yellow

$webAppObjectId = (az ad app show --id $creds.WebAppAppId --query "id" -o tsv)

# Website Contributor
az role assignment create --assignee $webAppObjectId --role "Website Contributor" `
  --resource-group $rgName --skip-assignment-validation 2>$null | Out-Null

# Web Plan Contributor
az role assignment create --assignee $webAppObjectId --role "Web Plan Contributor" `
  --resource-group $rgName --skip-assignment-validation 2>$null | Out-Null

Write-Host "✓ Web App roles assigned (Website Contributor, Web Plan Contributor)" -ForegroundColor Green

# ===== STEP 15-16: Create GitHub Secrets & Variables =====
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 15-16: Creating GitHub Secrets & Variables" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Check if gh CLI is available
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Host "ERROR: GitHub CLI (gh) is required but not found!" -ForegroundColor Red
  Write-Host "Install from: https://cli.github.com/" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "Manual alternative:" -ForegroundColor Yellow
  Write-Host "  1. Go to https://github.com/$gitHubOrg/$gitHubRepo/settings/secrets/actions" -ForegroundColor Yellow
  Write-Host "  2. Add each secret shown below" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "SECRETS to create:" -ForegroundColor Cyan
  Write-Host "  CLIENT_ID           = $($creds.AzGovVizAppId)"
  Write-Host "  ENTRA_CLIENT_ID     = $($creds.WebAppAppId)"
  Write-Host "  ENTRA_CLIENT_SECRET = $($creds.WebAppSecret)"
  Write-Host "  SUBSCRIPTION_ID     = $($creds.subscriptionId)"
  Write-Host "  TENANT_ID           = $($creds.tenantId)"
  Write-Host "  MANAGEMENT_GROUP_ID = $managementGroupId"
  Write-Host ""
  Write-Host "VARIABLES to create:" -ForegroundColor Cyan
  Write-Host "  RESOURCE_GROUP_NAME = $rgName"
  Write-Host "  WEB_APP_NAME        = $($creds.webAppName)"
  
  $useGhCli = Read-Host "Continue without gh CLI? (y/n)"
  if ($useGhCli -ne 'y') { exit 0 }
} else {
  Write-Host "Using GitHub CLI to create secrets and variables..." -ForegroundColor Yellow
  
  # Check gh auth
  gh auth status >$null 2>&1
  if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not authenticated with GitHub CLI. Run: gh auth login" -ForegroundColor Red
    exit 1
  }
  
  # Create secrets
  Write-Host "Creating GitHub secrets..." -ForegroundColor Yellow
  
  gh secret set 'CLIENT_ID' -b $creds.AzGovVizAppId --repo "$gitHubOrg/$gitHubRepo"
  gh secret set 'ENTRA_CLIENT_ID' -b $creds.WebAppAppId --repo "$gitHubOrg/$gitHubRepo"
  gh secret set 'ENTRA_CLIENT_SECRET' -b $creds.WebAppSecret --repo "$gitHubOrg/$gitHubRepo"
  gh secret set 'SUBSCRIPTION_ID' -b $creds.subscriptionId --repo "$gitHubOrg/$gitHubRepo"
  gh secret set 'TENANT_ID' -b $creds.tenantId --repo "$gitHubOrg/$gitHubRepo"
  gh secret set 'MANAGEMENT_GROUP_ID' -b $managementGroupId --repo "$gitHubOrg/$gitHubRepo"
  
  Write-Host "✓ All secrets created" -ForegroundColor Green
  
  # Create variables
  Write-Host "Creating GitHub variables..." -ForegroundColor Yellow
  
  gh variable set 'RESOURCE_GROUP_NAME' -b $rgName --repo "$gitHubOrg/$gitHubRepo"
  gh variable set 'WEB_APP_NAME' -b $creds.webAppName --repo "$gitHubOrg/$gitHubRepo"
  
  Write-Host "✓ All variables created" -ForegroundColor Green
  
  # Configure GitHub Actions permissions
  Write-Host "Configuring GitHub Actions permissions..." -ForegroundColor Yellow
  
  gh api -X PUT "/repos/$gitHubOrg/$gitHubRepo/actions/permissions/workflow" -F can_approve_pull_request_reviews=true 2>$null
  
  Write-Host "✓ GitHub Actions permissions configured" -ForegroundColor Green
}

# ===== SUMMARY AND NEXT STEPS =====
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✓ PHASE 2 COMPLETE - Setup Summary" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$summary = @{
  "Service Principal" = $creds.AzGovVizAppId
  "Web App Auth App" = $creds.WebAppAppId
  "Subscription" = $creds.subscriptionId
  "Tenant" = $creds.tenantId
  "Management Group" = $managementGroupId
  "Resource Group" = $rgName
  "Web App Name" = $creds.webAppName
  "GitHub Org" = $gitHubOrg
  "GitHub Repo" = $gitHubRepo
  "GitHub Branch" = $gitHubBranch
}

$summary.GetEnumerator() | ForEach-Object {
  Write-Host "$($_.Key)$(': ' * ([Math]::Max(1, 25 - $_.Key.Length))): $($_.Value)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Navigate to GitHub Actions:" -ForegroundColor Yellow
Write-Host "   https://github.com/$gitHubOrg/$gitHubRepo/actions" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Run 'DeployAzGovVizAccelerator' workflow:" -ForegroundColor Yellow
Write-Host "   - This creates the Azure Web App and configures authentication" -ForegroundColor Gray
Write-Host "   - Optionally specify an Entra ID group ObjectId for access control" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Wait for 'SyncAzGovViz' workflow to complete automatically" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Run 'DeployAzGovViz' workflow:" -ForegroundColor Yellow
Write-Host "   - Deploy and publish the visualizer to the web app" -ForegroundColor Gray
Write-Host "   - Configure parameters (e.g., NoPIMEligibility if needed)" -ForegroundColor Gray
Write-Host "   - Enable schedule if you want continuous runs" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Verify access:" -ForegroundColor Yellow
Write-Host "   - Azure Portal → $rgName → $($creds.webAppName)" -ForegroundColor Cyan
Write-Host "   - Click 'Browse' and authenticate with Entra ID" -ForegroundColor Gray
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
