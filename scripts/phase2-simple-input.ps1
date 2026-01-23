#!/usr/bin/env pwsh
# Phase 2 - Simplified Interactive Setup
# This gathers input and then executes Phase 2 automation

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Phase 2: Federated Credentials & GitHub Setup            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "FIXED VALUES FROM PHASE 1:" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" 
Write-Host "Subscription:        976c53b8-965c-4f97-ab51-993195a8623c"
Write-Host "Tenant:              54d665dd-30f1-45c5-a8d5-d6ffcdb518f9"
Write-Host "Region:              eastus2"
Write-Host "Web App:             azgovviz-web-cf0f6a7e"
Write-Host "Resource Group:      rg-azgovviz-cf0f6a7e"
Write-Host "Management Group:    Azure Landing Zones"
Write-Host ""

Write-Host "WHERE TO GET PHASE 1 VALUES:" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────"
Write-Host "1. Go to https://entra.microsoft.com/" -ForegroundColor Yellow
Write-Host "2. Click 'App registrations'"
Write-Host "3. Find 'azgovviz-accelerator-01' → copy Application ID & Object ID"
Write-Host "4. Find 'azgovviz-web-auth-cf0f6a7e' → copy Application ID"
Write-Host "5. Go to that app's Certificates & Secrets → view the secret"
Write-Host ""

Write-Host "GATHERING PHASE 2 INPUT VALUES:" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────"
Write-Host ""

# GitHub info
Write-Host "GitHub Information:" -ForegroundColor Yellow
$gitHubOrg = Read-Host "Enter GitHub username or organization"
if ([string]::IsNullOrEmpty($gitHubOrg)) {
    Write-Host "ERROR: Cannot be empty" -ForegroundColor Red
    exit 1
}

$gitHubRepo = Read-Host "Enter GitHub repository name (press ENTER for: Azure-Governance-Visualizer)"
if ([string]::IsNullOrEmpty($gitHubRepo)) { $gitHubRepo = "Azure-Governance-Visualizer" }

$gitHubBranch = Read-Host "Enter GitHub branch (press ENTER for: main)"
if ([string]::IsNullOrEmpty($gitHubBranch)) { $gitHubBranch = "main" }

Write-Host ""

# Phase 1 values
Write-Host "Phase 1 Credentials:" -ForegroundColor Yellow
$svcPrincipalId = Read-Host "Enter Service Principal Application ID (AzGovVizAppId)"
if ([string]::IsNullOrEmpty($svcPrincipalId)) {
    Write-Host "ERROR: Cannot be empty" -ForegroundColor Red
    exit 1
}

$svcPrincipalObjId = Read-Host "Enter Service Principal Object ID (AzGovVizAppObjectId)"
if ([string]::IsNullOrEmpty($svcPrincipalObjId)) {
    Write-Host "ERROR: Cannot be empty" -ForegroundColor Red
    exit 1
}

$webAppAppId = Read-Host "Enter Web App Application ID (WebAppAppId)"
if ([string]::IsNullOrEmpty($webAppAppId)) {
    Write-Host "ERROR: Cannot be empty" -ForegroundColor Red
    exit 1
}

Write-Host "Enter Web App Client Secret (this will be hidden):" -ForegroundColor Yellow
$webAppSecret = Read-Host "Web App Client Secret" -AsSecureString
if ($webAppSecret.Length -eq 0) {
    Write-Host "ERROR: Cannot be empty" -ForegroundColor Red
    exit 1
}
$webAppSecretText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemAlloc($webAppSecret))

# Confirmation
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PLEASE VERIFY - All Values Will Be Used in Phase 2:" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "GitHub:" -ForegroundColor Yellow
Write-Host "  Organization: $gitHubOrg" -ForegroundColor Gray
Write-Host "  Repository:   $gitHubRepo" -ForegroundColor Gray
Write-Host "  Branch:       $gitHubBranch" -ForegroundColor Gray
Write-Host ""
Write-Host "Phase 1 IDs:" -ForegroundColor Yellow
Write-Host "  Service Principal ID:       $svcPrincipalId" -ForegroundColor Gray
Write-Host "  Service Principal Obj ID:   $svcPrincipalObjId" -ForegroundColor Gray
Write-Host "  Web App App ID:             $webAppAppId" -ForegroundColor Gray
Write-Host "  Web App Secret:             ••••••••" -ForegroundColor Gray
Write-Host ""

$proceed = Read-Host "Is everything correct? (yes/no)"
if ($proceed -ne 'yes' -and $proceed -ne 'y') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "✓ Proceeding with Phase 2 setup..." -ForegroundColor Green
Write-Host ""

# Save configuration
$config = @{
    gitHubOrg = $gitHubOrg
    gitHubRepo = $gitHubRepo
    gitHubBranch = $gitHubBranch
    AzGovVizAppId = $svcPrincipalId
    AzGovVizAppObjectId = $svcPrincipalObjId
    WebAppAppId = $webAppAppId
    WebAppSecret = $webAppSecretText
    subscriptionId = "976c53b8-965c-4f97-ab51-993195a8623c"
    tenantId = "54d665dd-30f1-45c5-a8d5-d6ffcdb518f9"
    managementGroupName = "Azure Landing Zones"
    webAppName = "azgovviz-web-cf0f6a7e"
    resourceGroupName = "rg-azgovviz-cf0f6a7e"
    region = "eastus2"
}

# Save to temp for Phase 2 script
$configJson = $config | ConvertTo-Json
$configPath = Join-Path ([System.IO.Path]::GetTempPath()) "phase2-input.json"
$configJson | Out-File -FilePath $configPath -Force

Write-Host "✓ Configuration saved" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Execute Phase 2 automation script" -ForegroundColor Cyan
Write-Host "Run: & '.\azgovviz-phase2-main.ps1'" -ForegroundColor Yellow
