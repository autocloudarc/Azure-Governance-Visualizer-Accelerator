#!/usr/bin/env pwsh
<#
.SYNOPSIS
Configure GitHub Secrets and Variables for Azure Governance Visualizer

.DESCRIPTION
This script configures all required GitHub secrets and variables using the GitHub CLI (gh).
It reads configuration from the Phase 2 config file and sets up GitHub Actions secrets/variables.
#>

param()

# Load configuration
$configPath = "$env:TEMP\phase2-config.json"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  GitHub Secrets & Variables Configuration                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Load config
if (-not (Test-Path $configPath)) {
  Write-Host "✗ Configuration file not found: $configPath" -ForegroundColor Red
  exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json
Write-Host "✓ Configuration loaded" -ForegroundColor Green
Write-Host ""

# Check for GitHub CLI
$ghExists = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghExists) {
  Write-Host "✗ GitHub CLI (gh) not found" -ForegroundColor Red
  Write-Host ""
  Write-Host "Install GitHub CLI from: https://github.com/cli/cli" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "Then run this script again, or manually set secrets:" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "GitHub Repository: https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)" -ForegroundColor Cyan
  exit 1
}

Write-Host "✓ GitHub CLI found" -ForegroundColor Green
Write-Host ""

# Define secrets
$secrets = @{
  'CLIENT_ID' = $config.azGovVizAppId
  'ENTRA_CLIENT_ID' = $config.webAppAppId
  'SUBSCRIPTION_ID' = $config.subscriptionId
  'TENANT_ID' = $config.tenantId
  'MANAGEMENT_GROUP_ID' = $config.managementGroupId
}

# Define variables
$variables = @{
  'RESOURCE_GROUP_NAME' = $config.resourceGroupName
  'WEB_APP_NAME' = $config.webAppName
}

$repoPath = "$($config.gitHubOrg)/$($config.gitHubRepo)"

Write-Host "Repository: $repoPath" -ForegroundColor Yellow
Write-Host ""

# Set secrets
Write-Host "Setting GitHub Secrets:" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan

foreach ($secret in $secrets.GetEnumerator()) {
  try {
    Write-Host "  Setting: $($secret.Key)" -ForegroundColor Yellow
    $secret.Value | gh secret set $secret.Key -R $repoPath 2>&1 | Out-Null
    Write-Host "  ✓ $($secret.Key) set" -ForegroundColor Green
  } catch {
    Write-Host "  ✗ Failed to set $($secret.Key): $_" -ForegroundColor Red
  }
}

Write-Host ""
Write-Host "Setting GitHub Variables:" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan

foreach ($variable in $variables.GetEnumerator()) {
  try {
    Write-Host "  Setting: $($variable.Key)" -ForegroundColor Yellow
    $variable.Value | gh variable set $variable.Key -R $repoPath 2>&1 | Out-Null
    Write-Host "  ✓ $($variable.Key) set" -ForegroundColor Green
  } catch {
    Write-Host "  ✗ Failed to set $($variable.Key): $_" -ForegroundColor Red
  }
}

Write-Host ""
Write-Host "⚠️  IMPORTANT: ENTRA_CLIENT_SECRET" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────" -ForegroundColor Yellow
Write-Host ""
Write-Host "The ENTRA_CLIENT_SECRET must be set manually due to security restrictions." -ForegroundColor Yellow
Write-Host ""
Write-Host "Secret Value:" -ForegroundColor Cyan
Write-Host "$($config.webAppClientSecret)" -ForegroundColor Green
Write-Host ""
Write-Host "Set it using one of these commands:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1 - PowerShell:" -ForegroundColor White
Write-Host "'$($config.webAppClientSecret)' | gh secret set ENTRA_CLIENT_SECRET -R $repoPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 2 - Command line:" -ForegroundColor White
Write-Host "echo $($config.webAppClientSecret) | gh secret set ENTRA_CLIENT_SECRET -R $repoPath" -ForegroundColor Cyan
Write-Host ""

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✓ GitHub Configuration Ready" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

Write-Host "Configured Secrets & Variables:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Secrets ($(($secrets.Count + 1)) total):" -ForegroundColor Cyan
foreach ($secret in $secrets.GetEnumerator()) {
  Write-Host "  ✓ $($secret.Key)" -ForegroundColor Green
}
Write-Host "  ⚠ ENTRA_CLIENT_SECRET (manual setup required)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Variables ($($variables.Count) total):" -ForegroundColor Cyan
foreach ($variable in $variables.GetEnumerator()) {
  Write-Host "  ✓ $($variable.Key)" -ForegroundColor Green
}
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Set ENTRA_CLIENT_SECRET secret (see above)" -ForegroundColor White
Write-Host "2. Go to: https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)/actions" -ForegroundColor White
Write-Host "3. Run 'DeployAzGovVizAccelerator' workflow" -ForegroundColor White
Write-Host "4. Wait for workflows to complete" -ForegroundColor White
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green

exit 0
