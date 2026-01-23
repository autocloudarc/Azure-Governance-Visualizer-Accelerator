#!/usr/bin/env pwsh
# Azure Governance Visualizer Accelerator - Automated Setup Script
# This script automates the 18-step deployment process

# ===== CONFIGURATION =====
$appName = "azgovviz-accelerator-01"
$region = "eastus2"
$managementGroupName = "Azure Landing Zones"
$resourceRandomString = (new-guid).guid.substring(0,8)
$webAppName = "azgovviz-web-$resourceRandomString"
$resourceGroupName = "rg-azgovviz-$resourceRandomString"
$webAuthAppName = "azgovviz-web-auth-$resourceRandomString"
$subscriptionId = (az account show --query id -o tsv)
$tenantId = (az account show --query tenantId -o tsv)

# ===== STEP 1-2: Verify Azure Login and gather config =====
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Azure Governance Visualizer - Accelerator Setup" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "CONFIGURATION SUMMARY:" -ForegroundColor Yellow
Write-Host "├─ Service Principal:    $appName"
Write-Host "├─ Region:               $region"
Write-Host "├─ Management Group:     $managementGroupName"
Write-Host "├─ Subscription ID:      $subscriptionId"
Write-Host "├─ Tenant ID:            $tenantId"
Write-Host "├─ Web App Name:         $webAppName"
Write-Host "├─ Resource Group:       $resourceGroupName"
Write-Host "├─ Web Auth App:         $webAuthAppName"
Write-Host "└─ Random String:        $resourceRandomString"
Write-Host ""

# ===== STEP 3-5: Create AzGovViz Service Principal =====
Write-Host "STEP 3-5: Creating AzGovViz Service Principal..." -ForegroundColor Green

# Install AzAPICall if needed
$module = Get-Module -Name "AzAPICall" -ListAvailable
if (-not $module) {
  Write-Host "Installing AzAPICall module..." -ForegroundColor Yellow
  Install-Module -Name AzAPICall -Force -Scope CurrentUser
}

# Initialize AzAPICall
$azAPICallConf = initAzAPICall -SkipAzContextSubscriptionValidation $true

# Create app registration
$MicrosoftGraphAppId = "00000003-0000-0000-c000-000000000000"
$apiEndPoint = $azAPICallConf['azAPIEndpointUrls'].MicrosoftGraph
$apiVersion = '/v1.0'

Write-Host "Fetching Microsoft Graph permissions..." -ForegroundColor Yellow

# Get Graph permissions
$graphSP = AzAPICall -uri "$apiEndPoint$apiVersion/servicePrincipals?`$filter=(displayName eq 'Microsoft Graph')" `
  -method GET -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual'

$appRole = $graphSP.appRoles | Where-Object { $_.value -eq 'Application.Read.All' } | Select-Object -ExpandProperty id
$userRole = $graphSP.appRoles | Where-Object { $_.value -eq 'User.Read.All' } | Select-Object -ExpandProperty id
$groupRole = $graphSP.appRoles | Where-Object { $_.value -eq 'Group.Read.All' } | Select-Object -ExpandProperty id
$pimRole = $graphSP.appRoles | Where-Object { $_.value -eq 'PrivilegedAccess.Read.AzureResources' } | Select-Object -ExpandProperty id

Write-Host "Creating app registration: $appName" -ForegroundColor Yellow

$appBody = @{
  displayName = $appName
  requiredResourceAccess = @(
    @{
      resourceAppId = $MicrosoftGraphAppId
      resourceAccess = @(
        @{ id = $appRole; type = "Role" },
        @{ id = $userRole; type = "Role" },
        @{ id = $groupRole; type = "Role" },
        @{ id = $pimRole; type = "Role" }
      )
    }
  )
} | ConvertTo-Json -Depth 10

$app = AzAPICall -uri "$apiEndPoint$apiVersion/applications" -method POST -body $appBody `
  -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual'

$appObjectId = $app.id
$appId = $app.appId

Write-Host "✓ App registration created: $appId" -ForegroundColor Green

# Wait for service principal
Write-Host "Waiting for service principal to sync..." -ForegroundColor Yellow
$count = 0
do {
  Start-Sleep -Seconds 5
  $count++
  $appCheck = AzAPICall -uri "$apiEndPoint$apiVersion/applications/$appObjectId" -method GET `
    -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual' -skipOnErrorCode 404 -errorAction SilentlyContinue
  if ($count -gt 30) { break }
} until ($null -ne $appCheck)

Write-Host "✓ Service principal ready" -ForegroundColor Green

# ===== STEP 6: Generate random string (done above) =====
Write-Host "STEP 6: Random string generated: $resourceRandomString" -ForegroundColor Green

# ===== STEP 7: Create Web Auth App Registration =====
Write-Host ""
Write-Host "STEP 7: Creating Web Auth App Registration..." -ForegroundColor Green

$redirectUri = "https://$webAppName.azurewebsites.net/.auth/login/aad/callback"

$webAppBody = @{
  displayName = $webAuthAppName
  web = @{
    redirectUris = @($redirectUri)
    implicitGrantSettings = @{
      enableIdTokenIssuance = $true
    }
  }
} | ConvertTo-Json -Depth 10

$webApp = AzAPICall -uri "$apiEndPoint$apiVersion/applications" -method POST -body $webAppBody `
  -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual'

$webAppObjectId = $webApp.id
$webAppAppId = $webApp.appId

Write-Host "✓ Web auth app created: $webAppAppId" -ForegroundColor Green

# Wait for web app SP
Write-Host "Waiting for web app service principal..." -ForegroundColor Yellow
$count = 0
do {
  Start-Sleep -Seconds 5
  $count++
  $webAppCheck = AzAPICall -uri "$apiEndPoint$apiVersion/applications/$webAppObjectId" -method GET `
    -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual' -skipOnErrorCode 404 -errorAction SilentlyContinue
  if ($count -gt 30) { break }
} until ($null -ne $webAppCheck)

# Patch web app with API scope and groupMembershipClaims
$patchBody = @{
  identifierUris = @("api://$webAppAppId")
  groupMembershipClaims = "SecurityGroup"
  api = @{
    oauth2PermissionScopes = @(
      @{
        value = "user_impersonation"
        adminConsentDescription = "AzGovViz Web App Microsoft Entra ID authentication"
        adminConsentDisplayName = "AzGovViz Web App Microsoft Entra ID authentication"
        type = "User"
        id = (new-guid).guid
      }
    )
  }
} | ConvertTo-Json -Depth 10

AzAPICall -uri "$apiEndPoint$apiVersion/applications/$webAppObjectId" -method PATCH -body $patchBody `
  -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual' | Out-Null

Write-Host "✓ Web app configured with API scope" -ForegroundColor Green

# Create web app client secret
$secretBody = @{
  passwordCredential = @{
    displayName = "AzGovVizWebAppSecret"
  }
} | ConvertTo-Json -Depth 10

$secret = AzAPICall -uri "$apiEndPoint$apiVersion/applications/$webAppObjectId/addPassword" -method POST -body $secretBody `
  -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual'

$webAppSecret = $secret.secretText

Write-Host "✓ Web app client secret created" -ForegroundColor Green

# ===== SAVE CREDENTIALS =====
$credentials = @{
  AzGovVizAppId = $appId
  AzGovVizAppObjectId = $appObjectId
  WebAppAppId = $webAppAppId
  WebAppAppObjectId = $webAppObjectId
  WebAppSecret = $webAppSecret
  appName = $appName
  webAppName = $webAppName
  resourceGroupName = $resourceGroupName
  region = $region
  subscriptionId = $subscriptionId
  tenantId = $tenantId
  managementGroupName = $managementGroupName
} | ConvertTo-Json

$credPath = Join-Path ([System.IO.Path]::GetTempPath()) "azgovviz-credentials.json"
$credentials | Out-File -FilePath $credPath -Force
Write-Host ""
Write-Host "✓ Credentials saved to: $credPath" -ForegroundColor Green

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "IMPORTANT: Admin Consent Required" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "You must grant admin consent for the $appName app registration." -ForegroundColor Yellow
Write-Host "Navigate to: https://entra.microsoft.com/admin/appRegistrations"
Write-Host "  1. Find '$appName'"
Write-Host "  2. Go to API permissions"
Write-Host "  3. Click 'Grant admin consent for [YourTenant]'"
Write-Host ""
Write-Host "After granting admin consent, credentials will be ready for GitHub."
Write-Host ""
