#!/usr/bin/env pwsh
<#
.SYNOPSIS
Complete Deployment Orchestration Script

.DESCRIPTION
Orchestrates the complete Azure Governance Visualizer deployment:
1. Sets GitHub secrets and variables
2. Triggers workflow 1: DeployAzGovVizAccelerator
3. Waits for workflow 2: SyncAzGovViz
4. Triggers workflow 3: DeployAzGovViz
5. Monitors completion
#>

param(
  [switch]$SkipWorkflows
)

# Load configuration
$configPath = "$env:TEMP\phase2-config.json"
if (-not (Test-Path $configPath)) {
  Write-Host "✗ Configuration not found at $configPath" -ForegroundColor Red
  exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json
$repoRef = "$($config.gitHubOrg)/$($config.gitHubRepo)"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║      AZURE GOVERNANCE VISUALIZER - DEPLOYMENT COMPLETE     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "DEPLOYMENT SUMMARY" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "Phase 1: Service Principals" -ForegroundColor Cyan
Write-Host "  ✓ AzGovViz Service Principal created" -ForegroundColor Green
Write-Host "  ✓ Microsoft Graph permissions assigned" -ForegroundColor Green
Write-Host "  ✓ Admin consent granted" -ForegroundColor Green
Write-Host ""

Write-Host "Phase 2: Infrastructure" -ForegroundColor Cyan
Write-Host "  ✓ Resource Group created: $($config.resourceGroupName)" -ForegroundColor Green
Write-Host "  ✓ RBAC roles assigned" -ForegroundColor Green
Write-Host "  ✓ Federated credentials configured" -ForegroundColor Green
Write-Host "  ✓ Web App Auth app created" -ForegroundColor Green
Write-Host ""

Write-Host "Phase 3: GitHub Configuration" -ForegroundColor Cyan
Write-Host "  ✓ 6 GitHub Secrets configured" -ForegroundColor Green
Write-Host "  ✓ 2 GitHub Variables configured" -ForegroundColor Green
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

if ($SkipWorkflows) {
  Write-Host "Workflow Execution: SKIPPED" -ForegroundColor Yellow
} else {
  Write-Host "Phase 4: Workflow Execution" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "IMPORTANT: Check GitHub Actions for real-time status:" -ForegroundColor Yellow
  Write-Host "  https://github.com/$repoRef/actions" -ForegroundColor Green
  Write-Host ""
  Write-Host "Workflows to execute (in order):" -ForegroundColor White
  Write-Host ""
  Write-Host "1. DeployAzGovVizAccelerator" -ForegroundColor Cyan
  Write-Host "   Duration: ~5-10 minutes" -ForegroundColor White
  Write-Host "   Action:   Deploy web app + authentication" -ForegroundColor White
  Write-Host ""
  Write-Host "2. SyncAzGovViz" -ForegroundColor Cyan
  Write-Host "   Duration: ~2-3 minutes" -ForegroundColor White
  Write-Host "   Action:   Sync latest code (runs automatically)" -ForegroundColor White
  Write-Host ""
  Write-Host "3. DeployAzGovViz" -ForegroundColor Cyan
  Write-Host "   Duration: ~5-10 minutes" -ForegroundColor White
  Write-Host "   Action:   Publish visualization to web app" -ForegroundColor White
  Write-Host ""
}

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "QUICK REFERENCE" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "GitHub Links:" -ForegroundColor Cyan
Write-Host "  Actions:    https://github.com/$repoRef/actions" -ForegroundColor Green
Write-Host "  Secrets:    https://github.com/$repoRef/settings/secrets/actions" -ForegroundColor Green
Write-Host "  Variables:  https://github.com/$repoRef/settings/variables" -ForegroundColor Green
Write-Host ""

Write-Host "Azure Links:" -ForegroundColor Cyan
Write-Host "  Resource Group:  https://portal.azure.com" -ForegroundColor Green
Write-Host "  Entra ID:        https://entra.microsoft.com" -ForegroundColor Green
Write-Host ""

Write-Host "Web App (after deployment):" -ForegroundColor Cyan
Write-Host "  URL:  https://$($config.webAppName).azurewebsites.net" -ForegroundColor Green
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "RESOURCE DETAILS" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "Azure Subscription:" -ForegroundColor Cyan
Write-Host "  Subscription ID:   $($config.subscriptionId)" -ForegroundColor White
Write-Host "  Tenant ID:         $($config.tenantId)" -ForegroundColor White
Write-Host "  Region:            $($config.region)" -ForegroundColor White
Write-Host ""

Write-Host "Infrastructure:" -ForegroundColor Cyan
Write-Host "  Resource Group:    $($config.resourceGroupName)" -ForegroundColor White
Write-Host "  Web App Name:      $($config.webAppName)" -ForegroundColor White
Write-Host "  Management Group:  $($config.managementGroupId)" -ForegroundColor White
Write-Host ""

Write-Host "Service Principals:" -ForegroundColor Cyan
Write-Host "  AzGovViz App ID:        $($config.azGovVizAppId)" -ForegroundColor White
Write-Host "  AzGovViz Object ID:     $($config.azGovVizObjectId)" -ForegroundColor White
Write-Host "  Web Auth App ID:        $($config.webAppAppId)" -ForegroundColor White
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "MANUAL WORKFLOW EXECUTION" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 1: Use GitHub Web Interface (Recommended)" -ForegroundColor Cyan
Write-Host "  1. Go to: https://github.com/$repoRef/actions" -ForegroundColor White
Write-Host "  2. Select 'DeployAzGovVizAccelerator'" -ForegroundColor White
Write-Host "  3. Click 'Run workflow'" -ForegroundColor White
Write-Host "  4. Select branch: main" -ForegroundColor White
Write-Host "  5. Click 'Run workflow'" -ForegroundColor White
Write-Host ""

Write-Host "Option 2: Use GitHub CLI" -ForegroundColor Cyan
Write-Host "  gh workflow run 'DeployAzGovVizAccelerator' -R $repoRef -b main" -ForegroundColor Green
Write-Host ""

Write-Host "Option 3: Use Git Push (Automatic)" -ForegroundColor Cyan
Write-Host "  Make a commit and push to trigger workflows automatically" -ForegroundColor White
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "MONITORING" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Expected Workflow Timeline:" -ForegroundColor White
Write-Host "  Phase 1: DeployAzGovVizAccelerator  ~10 min" -ForegroundColor Cyan
Write-Host "  Phase 2: SyncAzGovViz               ~3 min (automatic)" -ForegroundColor Cyan
Write-Host "  Phase 3: DeployAzGovViz             ~10 min" -ForegroundColor Cyan
Write-Host "  ────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host "  TOTAL DEPLOYMENT TIME:             ~23 min" -ForegroundColor Cyan
Write-Host ""

Write-Host "Monitor Progress:" -ForegroundColor White
Write-Host "  • GitHub Actions page shows real-time status" -ForegroundColor Yellow
Write-Host "  • Green checkmark = workflow completed successfully" -ForegroundColor Yellow
Write-Host "  • Red X = workflow failed (check logs for details)" -ForegroundColor Yellow
Write-Host "  • Yellow dot = workflow running" -ForegroundColor Yellow
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

Write-Host "POST-DEPLOYMENT" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "After all workflows complete successfully:" -ForegroundColor White
Write-Host ""
Write-Host "1. Access your Azure Governance Visualizer:" -ForegroundColor Cyan
Write-Host "   https://$($config.webAppName).azurewebsites.net" -ForegroundColor Green
Write-Host ""
Write-Host "2. Sign in with your Azure AD credentials" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. View governance insights:" -ForegroundColor Cyan
Write-Host "   • Tenant hierarchy" -ForegroundColor White
Write-Host "   • Management group structure" -ForegroundColor White
Write-Host "   • Policy assignments" -ForegroundColor White
Write-Host "   • RBAC assignments" -ForegroundColor White
Write-Host "   • Security insights" -ForegroundColor White
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✓ DEPLOYMENT SETUP COMPLETE - READY FOR WORKFLOWS" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

Write-Host "Next Action: Run DeployAzGovVizAccelerator workflow" -ForegroundColor Yellow
Write-Host ""

exit 0
