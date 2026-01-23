#!/usr/bin/env pwsh
# Phase 2 Input Gathering Script
# This script collects all necessary values for Phase 2 setup

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Azure Governance Visualizer - Phase 2 Input Gathering" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Fixed values from Phase 1
$config = @{
  subscriptionId = "976c53b8-965c-4f97-ab51-993195a8623c"
  tenantId = "54d665dd-30f1-45c5-a8d5-d6ffcdb518f9"
  region = "eastus2"
  webAppName = "azgovviz-web-cf0f6a7e"
  resourceGroupName = "rg-azgovviz-cf0f6a7e"
  managementGroupName = "Azure Landing Zones"
}

Write-Host "PHASE 1 FIXED CONFIGURATION:" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host "Subscription ID:        $($config.subscriptionId)" -ForegroundColor Yellow
Write-Host "Tenant ID:              $($config.tenantId)" -ForegroundColor Yellow
Write-Host "Region:                 $($config.region)" -ForegroundColor Yellow
Write-Host "Web App Name:           $($config.webAppName)" -ForegroundColor Yellow
Write-Host "Resource Group:         $($config.resourceGroupName)" -ForegroundColor Yellow
Write-Host "Management Group:       $($config.managementGroupName)" -ForegroundColor Yellow
Write-Host ""

# Gather GitHub information
Write-Host "PHASE 2 REQUIRED INPUT:" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host ""

Write-Host "GitHub Configuration:" -ForegroundColor Yellow
$gitHubOrg = Read-Host "  1. GitHub username or organization (e.g., 'prestopa')"
if ([string]::IsNullOrEmpty($gitHubOrg)) {
  Write-Host "ERROR: GitHub org cannot be empty" -ForegroundColor Red
  exit 1
}

$gitHubRepo = Read-Host "  2. GitHub repository name [default: Azure-Governance-Visualizer]"
if ([string]::IsNullOrEmpty($gitHubRepo)) { $gitHubRepo = "Azure-Governance-Visualizer" }

$gitHubBranch = Read-Host "  3. GitHub branch [default: main]"
if ([string]::IsNullOrEmpty($gitHubBranch)) { $gitHubBranch = "main" }

Write-Host ""
Write-Host "Phase 1 Application IDs (from Phase 1 output):" -ForegroundColor Yellow
$svcPrincipalId = Read-Host "  4. Service Principal Application ID (AzGovVizAppId)"
if ([string]::IsNullOrEmpty($svcPrincipalId)) {
  Write-Host "ERROR: Service Principal ID cannot be empty" -ForegroundColor Red
  exit 1
}

$svcPrincipalObjId = Read-Host "  5. Service Principal Object ID (AzGovVizAppObjectId)"
if ([string]::IsNullOrEmpty($svcPrincipalObjId)) {
  Write-Host "ERROR: Service Principal Object ID cannot be empty" -ForegroundColor Red
  exit 1
}

$webAppAppId = Read-Host "  6. Web App Application ID (WebAppAppId)"
if ([string]::IsNullOrEmpty($webAppAppId)) {
  Write-Host "ERROR: Web App Application ID cannot be empty" -ForegroundColor Red
  exit 1
}

$webAppSecret = Read-Host "  7. Web App Client Secret (WebAppSecret)" -AsSecureString
if ([string]::IsNullOrEmpty($webAppSecret)) {
  Write-Host "ERROR: Web App Secret cannot be empty" -ForegroundColor Red
  exit 1
}
$webAppSecretText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemAlloc($webAppSecret))

# Display summary
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "SUMMARY - Please Verify All Values:" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "GitHub Configuration:" -ForegroundColor Yellow
Write-Host "  Organization:        $gitHubOrg" -ForegroundColor Gray
Write-Host "  Repository:          $gitHubRepo" -ForegroundColor Gray
Write-Host "  Branch:              $gitHubBranch" -ForegroundColor Gray
Write-Host ""
Write-Host "Azure Configuration:" -ForegroundColor Yellow
Write-Host "  Service Principal ID:       $svcPrincipalId" -ForegroundColor Gray
Write-Host "  Service Principal Obj ID:   $svcPrincipalObjId" -ForegroundColor Gray
Write-Host "  Web App Application ID:     $webAppAppId" -ForegroundColor Gray
Write-Host "  Subscription:               $($config.subscriptionId)" -ForegroundColor Gray
Write-Host "  Tenant:                     $($config.tenantId)" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Is all information correct? (yes/no)"
if ($confirm -ne 'yes' -and $confirm -ne 'y') {
  Write-Host "Setup cancelled." -ForegroundColor Yellow
  exit 0
}

# Save to file for Phase 2 script
$allConfig = $config + @{
  gitHubOrg = $gitHubOrg
  gitHubRepo = $gitHubRepo
  gitHubBranch = $gitHubBranch
  AzGovVizAppId = $svcPrincipalId
  AzGovVizAppObjectId = $svcPrincipalObjId
  WebAppAppId = $webAppAppId
  WebAppSecret = $webAppSecretText
}

$configPath = Join-Path $PSScriptRoot "phase2-config.json"
$allConfig | ConvertTo-Json | Out-File -FilePath $configPath -Force

Write-Host ""
Write-Host "✓ Configuration saved to: $configPath" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Run Phase 2 automation:" -ForegroundColor Cyan
Write-Host "  & .\azgovviz-phase2-execute.ps1" -ForegroundColor Yellow
