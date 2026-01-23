#!/usr/bin/env pwsh
<#
.SYNOPSIS
Creates Phase 2 configuration directly for Azure Governance Visualizer

.DESCRIPTION
This script creates the Phase 2 configuration file with all values from Phase 1
and the newly created web app auth app.
#>

param()

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  Phase 2: Creating Configuration                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Configuration values from Phase 1 and Web App Auth creation
$config = @{
  # Fixed values from Phase 1
  subscriptionId = "976c53b8-965c-4f97-ab51-993195a8623c"
  tenantId = "54d665dd-30f1-45c5-a8d5-d6ffcdb518f9"
  region = "eastus2"
  webAppName = "azgovviz-web-cf0f6a7e"
  resourceGroupName = "rg-azgovviz-cf0f6a7e"
  managementGroupId = "Azure Landing Zones"
  
  # GitHub configuration
  gitHubOrg = "autocloudarc"
  gitHubRepo = "Azure-Governance-Visualizer"
  gitHubBranch = "main"
  
  # Phase 1 Service Principal (AzGovViz)
  azGovVizAppId = "4ff7ea90-1c5d-4a98-9c96-00b7f43c5d47"
  azGovVizObjectId = "91b1f392-6988-4365-82a3-a3e67876bc7b"
  
  # Web App Auth App (newly created)
  webAppAppId = "514f9ecd-cf3b-4dc2-bbbf-69be251f27ee"
  webAppClientSecret = "G2L8Q~eiXzr7~VMwpN9pWYSQyeGsTheX53jD~b~r"
  
  # Timestamp
  createdAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

# Display configuration
Write-Host "PHASE 2 CONFIGURATION:" -ForegroundColor Yellow
Write-Host ""
Write-Host "GitHub:" -ForegroundColor Cyan
Write-Host "  Organization: $($config.gitHubOrg)" -ForegroundColor White
Write-Host "  Repository:   $($config.gitHubRepo)" -ForegroundColor White
Write-Host "  Branch:       $($config.gitHubBranch)" -ForegroundColor White
Write-Host ""
Write-Host "Azure Governance Visualizer Service Principal:" -ForegroundColor Cyan
Write-Host "  App ID:       $($config.azGovVizAppId)" -ForegroundColor White
Write-Host "  Object ID:    $($config.azGovVizObjectId)" -ForegroundColor White
Write-Host ""
Write-Host "Web App Auth Application:" -ForegroundColor Cyan
Write-Host "  App ID:       $($config.webAppAppId)" -ForegroundColor White
Write-Host "  Secret:       ••••••••••••••••••••••••••••" -ForegroundColor White
Write-Host ""
Write-Host "Azure Resources:" -ForegroundColor Cyan
Write-Host "  Subscription:      $($config.subscriptionId)" -ForegroundColor White
Write-Host "  Tenant:            $($config.tenantId)" -ForegroundColor White
Write-Host "  Resource Group:    $($config.resourceGroupName)" -ForegroundColor White
Write-Host "  Web App:           $($config.webAppName)" -ForegroundColor White
Write-Host "  Management Group:  $($config.managementGroupId)" -ForegroundColor White
Write-Host "  Region:            $($config.region)" -ForegroundColor White
Write-Host ""

# Save configuration
$configPath = "$env:TEMP\phase2-config.json"
$config | ConvertTo-Json | Set-Content -Path $configPath -Force

Write-Host "✓ Configuration saved to: $configPath" -ForegroundColor Green
Write-Host ""

# Confirm
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "Configuration ready for Phase 2 automation" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Run federated credentials setup" -ForegroundColor White
Write-Host "2. Create resource group and assign RBAC roles" -ForegroundColor White
Write-Host "3. Configure GitHub secrets and variables" -ForegroundColor White
Write-Host "4. Deploy GitHub Actions workflows" -ForegroundColor White
Write-Host ""

exit 0
