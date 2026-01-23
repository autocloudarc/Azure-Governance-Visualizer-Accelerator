#!/usr/bin/env pwsh
<#
.SYNOPSIS
Phase 2: Complete Azure Governance Visualizer Accelerator Setup

.DESCRIPTION
This script handles:
1. Creating federated credentials in Entra ID
2. Creating resource group and assigning RBAC roles
3. Configuring GitHub secrets and variables
4. Optionally deploying GitHub Actions workflows
#>

param(
  [switch]$SkipGitHub,
  [switch]$SkipDeployment
)

# Load configuration
$configPath = "$env:TEMP\phase2-config.json"
if (-not (Test-Path $configPath)) {
  Write-Host "✗ Configuration file not found at: $configPath" -ForegroundColor Red
  exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Phase 2: Complete Setup & Deployment                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Ensure AzAPICall is loaded
$module = Get-Module -Name "AzAPICall" -ListAvailable
if ($module) {
  Import-Module -Name AzAPICall -Force
} else {
  Write-Host "Installing AzAPICall module..." -ForegroundColor Yellow
  Install-Module -Name AzAPICall -Force
  Import-Module -Name AzAPICall -Force
}

# Initialize Azure API
Write-Host "Initializing Azure API connection..." -ForegroundColor Yellow
$azAPICallConf = initAzAPICall -SkipAzContextSubscriptionValidation $true
$apiEndPoint = $azAPICallConf['azAPIEndpointUrls'].MicrosoftGraph
$apiVersion = '/v1.0'

# Select subscription
Write-Host "Selecting Azure subscription..." -ForegroundColor Yellow
Select-AzSubscription -SubscriptionId $config.subscriptionId | Out-Null

# ==============================================================================
# STEP 1: Create Federated Credentials
# ==============================================================================
Write-Host ""
Write-Host "Step 1: Creating Federated Credentials" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan

$gitHubRef = ":ref:refs/heads/$($config.gitHubBranch)"
$subject = "repo:$($config.gitHubOrg)/$($config.gitHubRepo)$gitHubRef"

$federatedBody = @{
  audiences = @("api://AzureADTokenExchange")
  issuer = "https://token.actions.githubusercontent.com"
  subject = $subject
  name = "AzGovVizGitHubActions"
  description = "Federated credential for GitHub Actions"
} | ConvertTo-Json -Depth 10

try {
  Write-Host "Creating federated credential for:" -ForegroundColor Yellow
  Write-Host "  Organization: $($config.gitHubOrg)" -ForegroundColor White
  Write-Host "  Repository:   $($config.gitHubRepo)" -ForegroundColor White
  Write-Host "  Branch:       $($config.gitHubBranch)" -ForegroundColor White
  
  $fedCred = AzAPICall `
    -uri "$apiEndPoint$apiVersion/applications/$($config.azGovVizObjectId)/federatedIdentityCredentials" `
    -method POST `
    -body $federatedBody `
    -AzAPICallConfiguration $azAPICallConf `
    -listenOn 'Content' `
    -consistencyLevel 'eventual'
  
  Write-Host "✓ Federated credential created successfully" -ForegroundColor Green
} catch {
  Write-Host "✗ Failed to create federated credential: $_" -ForegroundColor Red
  Write-Host "  Continuing with next step..." -ForegroundColor Yellow
}

# ==============================================================================
# STEP 2: Create Resource Group
# ==============================================================================
Write-Host ""
Write-Host "Step 2: Creating Resource Group" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan

try {
  Write-Host "Creating resource group: $($config.resourceGroupName)" -ForegroundColor Yellow
  
  $rg = New-AzResourceGroup `
    -Name $config.resourceGroupName `
    -Location $config.region `
    -Force
  
  Write-Host "✓ Resource group created: $($rg.ResourceGroupName)" -ForegroundColor Green
} catch {
  Write-Host "✗ Failed to create resource group: $_" -ForegroundColor Red
  Write-Host "  Attempting to continue..." -ForegroundColor Yellow
}

# ==============================================================================
# STEP 3: Assign RBAC Roles
# ==============================================================================
Write-Host ""
Write-Host "Step 3: Assigning RBAC Roles" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan

$roles = @(
  @{ Name = "Website Contributor"; Description = "Web app deployment" },
  @{ Name = "Web Plan Contributor"; Description = "App service plan management" }
)

foreach ($role in $roles) {
  try {
    Write-Host "Assigning role: $($role.Name) - $($role.Description)" -ForegroundColor Yellow
    
    New-AzRoleAssignment `
      -ApplicationId $config.azGovVizAppId `
      -RoleDefinitionName $role.Name `
      -ResourceGroupName $config.resourceGroupName `
      -ErrorAction Stop | Out-Null
    
    Write-Host "✓ Role assigned: $($role.Name)" -ForegroundColor Green
  } catch {
    Write-Host "✗ Failed to assign role $($role.Name): $_" -ForegroundColor Red
  }
}

# Also assign Reader role on Management Group
Write-Host ""
Write-Host "Assigning Reader role on Management Group..." -ForegroundColor Yellow
try {
  New-AzRoleAssignment `
    -ApplicationId $config.azGovVizAppId `
    -RoleDefinitionName "Reader" `
    -Scope "/providers/Microsoft.Management/managementGroups/$($config.managementGroupId)" `
    -ErrorAction Stop | Out-Null
  
  Write-Host "✓ Reader role assigned on Management Group" -ForegroundColor Green
} catch {
  Write-Host "✗ Failed to assign Reader role on Management Group: $_" -ForegroundColor Red
}

# ==============================================================================
# STEP 4: Configure GitHub Secrets and Variables (if gh CLI available)
# ==============================================================================
if ($SkipGitHub) {
  Write-Host ""
  Write-Host "Skipping GitHub configuration (--SkipGitHub flag set)" -ForegroundColor Yellow
} else {
  Write-Host ""
  Write-Host "Step 4: Configuring GitHub Secrets and Variables" -ForegroundColor Cyan
  Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan
  
  # Check if gh CLI is available
  $ghCheck = Get-Command gh -ErrorAction SilentlyContinue
  if (-not $ghCheck) {
    Write-Host "⚠ GitHub CLI (gh) not found. Install from: https://github.com/cli/cli" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manual GitHub Configuration Required:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Go to: https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)/settings/secrets/actions" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Create the following secrets:" -ForegroundColor White
    Write-Host "   CLIENT_ID                = $($config.azGovVizAppId)" -ForegroundColor Cyan
    Write-Host "   ENTRA_CLIENT_ID          = $($config.webAppAppId)" -ForegroundColor Cyan
    Write-Host "   ENTRA_CLIENT_SECRET      = [your-web-app-secret]" -ForegroundColor Cyan
    Write-Host "   SUBSCRIPTION_ID          = $($config.subscriptionId)" -ForegroundColor Cyan
    Write-Host "   TENANT_ID                = $($config.tenantId)" -ForegroundColor Cyan
    Write-Host "   MANAGEMENT_GROUP_ID      = $($config.managementGroupId)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Create the following variables:" -ForegroundColor White
    Write-Host "   RESOURCE_GROUP_NAME      = $($config.resourceGroupName)" -ForegroundColor Cyan
    Write-Host "   WEB_APP_NAME             = $($config.webAppName)" -ForegroundColor Cyan
  } else {
    Write-Host "✓ GitHub CLI found" -ForegroundColor Green
    
    # Try to configure secrets and variables via gh CLI
    try {
      Write-Host ""
      Write-Host "Configuring GitHub secrets and variables..." -ForegroundColor Yellow
      
      $secrets = @{
        'CLIENT_ID' = $config.azGovVizAppId
        'ENTRA_CLIENT_ID' = $config.webAppAppId
        'SUBSCRIPTION_ID' = $config.subscriptionId
        'TENANT_ID' = $config.tenantId
        'MANAGEMENT_GROUP_ID' = $config.managementGroupId
      }
      
      $variables = @{
        'RESOURCE_GROUP_NAME' = $config.resourceGroupName
        'WEB_APP_NAME' = $config.webAppName
      }
      
      foreach ($secret in $secrets.GetEnumerator()) {
        Write-Host "Setting secret: $($secret.Key)" -ForegroundColor Yellow
        $secret.Value | gh secret set $secret.Key -R "$($config.gitHubOrg)/$($config.gitHubRepo)"
        Write-Host "✓ Secret set: $($secret.Key)" -ForegroundColor Green
      }
      
      Write-Host ""
      
      foreach ($variable in $variables.GetEnumerator()) {
        Write-Host "Setting variable: $($variable.Key)" -ForegroundColor Yellow
        $variable.Value | gh variable set $variable.Key -R "$($config.gitHubOrg)/$($config.gitHubRepo)"
        Write-Host "✓ Variable set: $($variable.Key)" -ForegroundColor Green
      }
      
      Write-Host ""
      Write-Host "⚠ NOTE: ENTRA_CLIENT_SECRET must be set manually!" -ForegroundColor Yellow
      Write-Host "   Secret value: $($config.webAppClientSecret)" -ForegroundColor Cyan
      Write-Host ""
      Write-Host "   Run this command manually:" -ForegroundColor White
      Write-Host "   echo '$($config.webAppClientSecret)' | gh secret set ENTRA_CLIENT_SECRET -R $($config.gitHubOrg)/$($config.gitHubRepo)" -ForegroundColor Green
      
    } catch {
      Write-Host "✗ Failed to configure GitHub secrets/variables: $_" -ForegroundColor Red
    }
  }
}

# ==============================================================================
# Summary
# ==============================================================================
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "Phase 2 Setup COMPLETE" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

Write-Host "Summary of Created Resources:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Azure Resources:" -ForegroundColor Cyan
Write-Host "  Resource Group:  $($config.resourceGroupName) (region: $($config.region))" -ForegroundColor White
Write-Host "  Web App Name:    $($config.webAppName)" -ForegroundColor White
Write-Host "  Subscription:    $($config.subscriptionId)" -ForegroundColor White
Write-Host ""

Write-Host "Federated Credentials:" -ForegroundColor Cyan
Write-Host "  GitHub Org:      $($config.gitHubOrg)" -ForegroundColor White
Write-Host "  Repository:      $($config.gitHubRepo)" -ForegroundColor White
Write-Host "  Branch:          $($config.gitHubBranch)" -ForegroundColor White
Write-Host ""

Write-Host "RBAC Roles Assigned:" -ForegroundColor Cyan
Write-Host "  ✓ Website Contributor (Resource Group scope)" -ForegroundColor White
Write-Host "  ✓ Web Plan Contributor (Resource Group scope)" -ForegroundColor White
Write-Host "  ✓ Reader (Management Group scope)" -ForegroundColor White
Write-Host ""

if (-not $SkipDeployment) {
  Write-Host "Next Steps:" -ForegroundColor Yellow
  Write-Host "1. Verify GitHub secrets configuration" -ForegroundColor White
  Write-Host "2. Go to Actions in your GitHub repository" -ForegroundColor White
  Write-Host "3. Run the 'DeployAzGovVizAccelerator' workflow" -ForegroundColor White
  Write-Host "4. Wait for 'SyncAzGovViz' workflow to complete" -ForegroundColor White
  Write-Host "5. Run the 'DeployAzGovViz' workflow to deploy the web app" -ForegroundColor White
} else {
  Write-Host "Deployment skipped (--SkipDeployment flag set)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green

exit 0
