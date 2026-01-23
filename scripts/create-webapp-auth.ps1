#!/usr/bin/env pwsh
<#
.SYNOPSIS
Creates the Web App Auth App Registration for AzGovViz

.DESCRIPTION
This script creates the missing azgovviz-web-auth-cf0f6a7e app registration
with proper configuration for Azure Web App authentication.
#>

param()

# Ensure AzAPICall is loaded
$module = Get-Module -Name "AzAPICall" -ListAvailable
if ($module) {
  Import-Module -Name AzAPICall -Force
} else {
  Write-Error "AzAPICall module not found. Please install it first."
  exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Creating Web App Auth App Registration                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Initialize AzAPICall
Write-Host "Initializing Azure API connection..." -ForegroundColor Yellow
$azAPICallConf = initAzAPICall -SkipAzContextSubscriptionValidation $true

$apiEndPoint = $azAPICallConf['azAPIEndpointUrls'].MicrosoftGraph
$apiVersion = '/v1.0'

# Configuration
$webAppName = "azgovviz-web-cf0f6a7e"
$webAuthAppName = "azgovviz-web-auth-cf0f6a7e"
$redirectUri = "https://$webAppName.azurewebsites.net/.auth/login/aad/callback"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  App Name:     $webAuthAppName" -ForegroundColor White
Write-Host "  Redirect URI: $redirectUri" -ForegroundColor White
Write-Host ""

# Step 1: Create the app registration
Write-Host "Step 1: Creating app registration..." -ForegroundColor Cyan

$webAppBody = @{
  displayName = $webAuthAppName
  web = @{
    redirectUris = @($redirectUri)
    implicitGrantSettings = @{
      enableIdTokenIssuance = $true
    }
  }
} | ConvertTo-Json -Depth 10

try {
  $webApp = AzAPICall -uri "$apiEndPoint$apiVersion/applications" -method POST -body $webAppBody `
    -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual'
  
  $webAppObjectId = $webApp.id
  $webAppAppId = $webApp.appId
  
  Write-Host "✓ App registration created" -ForegroundColor Green
  Write-Host "  AppId: $webAppAppId" -ForegroundColor Cyan
  Write-Host "  ObjId: $webAppObjectId" -ForegroundColor Cyan
} catch {
  Write-Host "✗ Failed to create app registration: $_" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "Step 2: Waiting for service principal creation..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Step 2: Configure API scope and group membership
Write-Host "Step 3: Configuring API scope and group membership..." -ForegroundColor Cyan

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
        id = (New-Guid).Guid
      }
    )
  }
} | ConvertTo-Json -Depth 10

try {
  AzAPICall -uri "$apiEndPoint$apiVersion/applications/$webAppObjectId" -method PATCH -body $patchBody `
    -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual' | Out-Null
  
  Write-Host "✓ API scope and group claims configured" -ForegroundColor Green
} catch {
  Write-Host "✗ Failed to configure API scope: $_" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "Step 4: Generating client secret..." -ForegroundColor Cyan

# Step 3: Create client secret
$secretBody = @{
  passwordCredential = @{
    displayName = "AzGovVizWebAppSecret"
  }
} | ConvertTo-Json -Depth 10

try {
  $secret = AzAPICall -uri "$apiEndPoint$apiVersion/applications/$webAppObjectId/addPassword" `
    -method POST -body $secretBody `
    -AzAPICallConfiguration $azAPICallConf -listenOn 'Content' -consistencyLevel 'eventual'
  
  $webAppSecret = $secret.secretText
  
  Write-Host "✓ Client secret created" -ForegroundColor Green
} catch {
  Write-Host "✗ Failed to create client secret: $_" -ForegroundColor Red
  exit 1
}

# Display results
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "SUCCESS: Web App Auth App Registration Created" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "SAVE THESE VALUES FOR PHASE 2:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Web App Application ID:" -ForegroundColor Cyan
Write-Host "  $webAppAppId" -ForegroundColor White
Write-Host ""
Write-Host "Web App Client Secret:" -ForegroundColor Cyan
Write-Host "  $webAppSecret" -ForegroundColor White
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# Save to temp file for Phase 2
$config = @{
  webAppAppId = $webAppAppId
  webAppSecret = $webAppSecret
} | ConvertTo-Json

$config | Set-Content -Path "$env:TEMP\phase2-webapp-auth.json" -Force
Write-Host "Configuration saved to: $env:TEMP\phase2-webapp-auth.json" -ForegroundColor Yellow
Write-Host ""

exit 0
