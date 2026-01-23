#!/usr/bin/env pwsh
<#
.SYNOPSIS
Phase 2: Simplified Setup Script
#>

param()

# Load configuration
$configPath = "$env:TEMP\phase2-config.json"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Phase 2: Setup Automation (Simplified)                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check configuration
if (-not (Test-Path $configPath)) {
  Write-Host "✗ Configuration file not found" -ForegroundColor Red
  Write-Host "Expected path: $configPath" -ForegroundColor Yellow
  exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json
Write-Host "✓ Configuration loaded from: $configPath" -ForegroundColor Green
Write-Host ""

# Select subscription
Write-Host "Step 1: Selecting Azure subscription..." -ForegroundColor Cyan
Write-Host "  Subscription: $($config.subscriptionId)" -ForegroundColor Yellow

try {
  Select-AzSubscription -SubscriptionId $config.subscriptionId -ErrorAction Stop | Out-Null
  Write-Host "✓ Subscription selected" -ForegroundColor Green
} catch {
  Write-Host "✗ Failed to select subscription: $_" -ForegroundColor Red
  exit 1
}

Write-Host ""

# Create resource group
Write-Host "Step 2: Creating resource group..." -ForegroundColor Cyan
Write-Host "  Name:     $($config.resourceGroupName)" -ForegroundColor Yellow
Write-Host "  Region:   $($config.region)" -ForegroundColor Yellow

try {
  $rg = New-AzResourceGroup `
    -Name $config.resourceGroupName `
    -Location $config.region `
    -Force `
    -ErrorAction Stop
  
  Write-Host "✓ Resource group created" -ForegroundColor Green
} catch {
  Write-Host "⚠ Resource group may already exist or error occurred: $_" -ForegroundColor Yellow
}

Write-Host ""

# Assign RBAC roles
Write-Host "Step 3: Assigning RBAC roles..." -ForegroundColor Cyan

$roles = @("Website Contributor", "Web Plan Contributor")

foreach ($role in $roles) {
  Write-Host "  Assigning role: $role" -ForegroundColor Yellow
  try {
    New-AzRoleAssignment `
      -ApplicationId $config.azGovVizAppId `
      -RoleDefinitionName $role `
      -ResourceGroupName $config.resourceGroupName `
      -ErrorAction Stop | Out-Null
    
    Write-Host "  ✓ $role assigned" -ForegroundColor Green
  } catch {
    Write-Host "  ⚠ Role assignment may already exist: $_" -ForegroundColor Yellow
  }
}

Write-Host ""

# Create federated credentials (requires AzAPICall)
Write-Host "Step 4: Creating federated credentials..." -ForegroundColor Cyan

try {
  $azAPICallConf = initAzAPICall -SkipAzContextSubscriptionValidation $true
  
  $gitHubRef = ":ref:refs/heads/$($config.gitHubBranch)"
  $subject = "repo:$($config.gitHubOrg)/$($config.gitHubRepo)$gitHubRef"
  
  $federatedBody = @{
    audiences = @("api://AzureADTokenExchange")
    issuer = "https://token.actions.githubusercontent.com"
    subject = $subject
    name = "AzGovVizGitHubActions"
  } | ConvertTo-Json -Depth 10
  
  AzAPICall `
    -uri "https://graph.microsoft.com/v1.0/applications/$($config.azGovVizObjectId)/federatedIdentityCredentials" `
    -method POST `
    -body $federatedBody `
    -AzAPICallConfiguration $azAPICallConf `
    -listenOn 'Content' `
    -consistencyLevel 'eventual' | Out-Null
  
  Write-Host "  GitHub Org:  $($config.gitHubOrg)" -ForegroundColor Yellow
  Write-Host "  Repository:  $($config.gitHubRepo)" -ForegroundColor Yellow
  Write-Host "  Branch:      $($config.gitHubBranch)" -ForegroundColor Yellow
  Write-Host "✓ Federated credential created" -ForegroundColor Green
} catch {
  Write-Host "✗ Failed to create federated credential: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✓ Phase 2 Setup Complete" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

Write-Host "Resources Created:" -ForegroundColor Yellow
Write-Host "  Resource Group: $($config.resourceGroupName)" -ForegroundColor Cyan
Write-Host "  Web App Name:   $($config.webAppName)" -ForegroundColor Cyan
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Set GitHub Secrets (https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)/settings/secrets/actions):" -ForegroundColor White
Write-Host "   SECRET                   VALUE" -ForegroundColor Cyan
Write-Host "   CLIENT_ID                $($config.azGovVizAppId)" -ForegroundColor Green
Write-Host "   ENTRA_CLIENT_ID          $($config.webAppAppId)" -ForegroundColor Green
Write-Host "   ENTRA_CLIENT_SECRET      [COPY FROM BELOW]" -ForegroundColor Yellow
Write-Host "   SUBSCRIPTION_ID          $($config.subscriptionId)" -ForegroundColor Green
Write-Host "   TENANT_ID                $($config.tenantId)" -ForegroundColor Green
Write-Host "   MANAGEMENT_GROUP_ID      $($config.managementGroupId)" -ForegroundColor Green
Write-Host ""
Write-Host "2. Set GitHub Variables (https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)/settings/variables):" -ForegroundColor White
Write-Host "   VARIABLE                 VALUE" -ForegroundColor Cyan
Write-Host "   RESOURCE_GROUP_NAME      $($config.resourceGroupName)" -ForegroundColor Green
Write-Host "   WEB_APP_NAME             $($config.webAppName)" -ForegroundColor Green
Write-Host ""
Write-Host "3. Copy and set ENTRA_CLIENT_SECRET secret:" -ForegroundColor White
Write-Host "   $($config.webAppClientSecret)" -ForegroundColor Green
Write-Host ""
Write-Host "4. Run GitHub Actions Workflows:" -ForegroundColor White
Write-Host "   a. DeployAzGovVizAccelerator (deploys web app infrastructure)" -ForegroundColor Cyan
Write-Host "   b. SyncAzGovViz (syncs latest Azure Governance Visualizer code)" -ForegroundColor Cyan
Write-Host "   c. DeployAzGovViz (publishes AzGovViz to the web app)" -ForegroundColor Cyan
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green

exit 0
