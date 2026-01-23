#!/usr/bin/env pwsh
<#
.SYNOPSIS
Phase 3: Final Steps - GitHub Configuration & Workflow Execution

.DESCRIPTION
This script guides you through:
1. Verifying GitHub secrets are configured
2. Understanding the workflow execution process
3. Providing direct links to GitHub Actions
#>

param()

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         PHASE 3: FINAL DEPLOYMENT STEPS                      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Load configuration
$configPath = "$env:TEMP\phase2-config.json"
if (-not (Test-Path $configPath)) {
  Write-Host "⚠ Configuration file not found" -ForegroundColor Yellow
  exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

Write-Host "GITHUB CONFIGURATION VERIFICATION" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "Repository Details:" -ForegroundColor Cyan
Write-Host "  Organization:  $($config.gitHubOrg)" -ForegroundColor White
Write-Host "  Repository:    $($config.gitHubRepo)" -ForegroundColor White
Write-Host "  Branch:        $($config.gitHubBranch)" -ForegroundColor White
Write-Host ""

Write-Host "GitHub Secrets Required (6 total):" -ForegroundColor Cyan
$secrets = @(
  @{ Name = "CLIENT_ID"; Value = $config.azGovVizAppId },
  @{ Name = "ENTRA_CLIENT_ID"; Value = $config.webAppAppId },
  @{ Name = "ENTRA_CLIENT_SECRET"; Value = "G2L8Q~eiXzr7~VMwpN9pWYSQyeGsTheX53jD~b~r" },
  @{ Name = "SUBSCRIPTION_ID"; Value = $config.subscriptionId },
  @{ Name = "TENANT_ID"; Value = $config.tenantId },
  @{ Name = "MANAGEMENT_GROUP_ID"; Value = $config.managementGroupId }
)

foreach ($secret in $secrets) {
  if ($secret.Name -eq "ENTRA_CLIENT_SECRET") {
    Write-Host "  ☐ $($secret.Name)" -ForegroundColor Yellow
  } else {
    Write-Host "  ☑ $($secret.Name)" -ForegroundColor Green
  }
}

Write-Host ""
Write-Host "GitHub Variables Required (2 total):" -ForegroundColor Cyan
$variables = @(
  @{ Name = "RESOURCE_GROUP_NAME"; Value = $config.resourceGroupName },
  @{ Name = "WEB_APP_NAME"; Value = $config.webAppName }
)

foreach ($variable in $variables) {
  Write-Host "  ☑ $($variable.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "MANUAL GITHUB SETUP REQUIRED" -ForegroundColor Red
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
Write-Host ""

Write-Host "IMPORTANT: Set ENTRA_CLIENT_SECRET manually (security restriction)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Go to: https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)/settings/secrets/actions" -ForegroundColor Cyan
Write-Host ""
Write-Host "Create secret:" -ForegroundColor White
Write-Host "  Name:  ENTRA_CLIENT_SECRET" -ForegroundColor Cyan
Write-Host "  Value: G2L8Q~eiXzr7~VMwpN9pWYSQyeGsTheX53jD~b~r" -ForegroundColor Green
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "GITHUB ACTIONS - WORKFLOWS TO RUN (IN ORDER)" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 1: Deploy Infrastructure" -ForegroundColor Cyan
Write-Host "  Workflow: DeployAzGovVizAccelerator" -ForegroundColor White
Write-Host "  Duration: 5-10 minutes" -ForegroundColor White
Write-Host "  Purpose:  Deploy web app and configure authentication" -ForegroundColor White
Write-Host ""
Write-Host "  URL: https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)/actions" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Sync Code (Automatic)" -ForegroundColor Cyan
Write-Host "  Workflow: SyncAzGovViz" -ForegroundColor White
Write-Host "  Duration: 2-3 minutes" -ForegroundColor White
Write-Host "  Purpose:  Sync latest Azure Governance Visualizer code" -ForegroundColor White
Write-Host "  Note:     Runs automatically after DeployAzGovVizAccelerator" -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 3: Deploy Visualization" -ForegroundColor Cyan
Write-Host "  Workflow: DeployAzGovViz" -ForegroundColor White
Write-Host "  Duration: 5-10 minutes" -ForegroundColor White
Write-Host "  Purpose:  Publish Azure Governance Visualizer to web app" -ForegroundColor White
Write-Host ""
Write-Host "  URL: https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)/actions" -ForegroundColor Green
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "WHAT EACH WORKFLOW DOES" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "DeployAzGovVizAccelerator:" -ForegroundColor Cyan
Write-Host "  ✓ Creates App Service Plan" -ForegroundColor Green
Write-Host "  ✓ Creates Web App ($($config.webAppName))" -ForegroundColor Green
Write-Host "  ✓ Configures Azure AD authentication" -ForegroundColor Green
Write-Host "  ✓ Sets up authentication policies" -ForegroundColor Green
Write-Host ""

Write-Host "SyncAzGovViz:" -ForegroundColor Cyan
Write-Host "  ✓ Syncs latest Azure Governance Visualizer code" -ForegroundColor Green
Write-Host "  ✓ Updates repository with releases" -ForegroundColor Green
Write-Host "  ✓ Prepares code for deployment" -ForegroundColor Green
Write-Host ""

Write-Host "DeployAzGovViz:" -ForegroundColor Cyan
Write-Host "  ✓ Runs Azure Governance Visualizer analysis" -ForegroundColor Green
Write-Host "  ✓ Generates reports and insights" -ForegroundColor Green
Write-Host "  ✓ Publishes to web app" -ForegroundColor Green
Write-Host "  ✓ Makes visualization accessible via web" -ForegroundColor Green
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "AFTER DEPLOYMENT COMPLETES" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "Access your Azure Governance Visualizer at:" -ForegroundColor Cyan
Write-Host "  https://$($config.webAppName).azurewebsites.net" -ForegroundColor Green
Write-Host ""

Write-Host "First time access:" -ForegroundColor White
Write-Host "  1. You'll be redirected to Azure AD login" -ForegroundColor Yellow
Write-Host "  2. Sign in with your Azure account" -ForegroundColor Yellow
Write-Host "  3. Access will be granted to authorized users" -ForegroundColor Yellow
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "QUICK LINKS" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "GitHub:" -ForegroundColor Cyan
Write-Host "  Actions:    https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)/actions" -ForegroundColor Green
Write-Host "  Secrets:    https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)/settings/secrets/actions" -ForegroundColor Green
Write-Host "  Variables:  https://github.com/$($config.gitHubOrg)/$($config.gitHubRepo)/settings/variables" -ForegroundColor Green
Write-Host ""
Write-Host "Azure:" -ForegroundColor Cyan
Write-Host "  Portal:     https://portal.azure.com" -ForegroundColor Green
Write-Host "  Entra ID:   https://entra.microsoft.com" -ForegroundColor Green
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "DEPLOYMENT CHECKLIST" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Before running workflows, verify:" -ForegroundColor White
Write-Host "  [ ] GitHub Secrets: 6 total (5 automated + ENTRA_CLIENT_SECRET manual)" -ForegroundColor Yellow
Write-Host "  [ ] GitHub Variables: 2 total" -ForegroundColor Yellow
Write-Host "  [ ] Azure Resource Group created: rg-azgovviz-cf0f6a7e" -ForegroundColor Yellow
Write-Host "  [ ] Service principal has required roles" -ForegroundColor Yellow
Write-Host "  [ ] Federated credentials configured" -ForegroundColor Yellow
Write-Host ""
Write-Host "Ready to proceed?" -ForegroundColor Cyan
Write-Host "  [ ] Run DeployAzGovVizAccelerator workflow" -ForegroundColor Green
Write-Host "  [ ] Wait for SyncAzGovViz workflow" -ForegroundColor Green
Write-Host "  [ ] Run DeployAzGovViz workflow" -ForegroundColor Green
Write-Host "  [ ] Access web app at: https://$($config.webAppName).azurewebsites.net" -ForegroundColor Green
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✓ READY FOR WORKFLOW EXECUTION" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

exit 0
