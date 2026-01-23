@description('Web app name')
@minLength(2)
param webAppName string = 'AzGovViz-${uniqueString(resourceGroup().id)}'

@description('Location for all resources')
param location string = resourceGroup().location

@description('The SKU of App Service Plan.')
param sku string

@description('The Runtime stack of the web app')
param runtimeStack string

@description('App Service Plan name')
param appServicePlanName string = 'AppServicePlan-${webAppName}'

@description('The kind of App Service Plan.')
param kind string = 'Windows'

@description('The public network access of the web app')
param publicNetworkAccess string

@description('The Microsoft Entra tenant ID of the Azure subscription (used for user authentication)')
param tenantId string = subscription().tenantId

@description('The client ID of the Microsoft Entra application (used for user authentication)')
param clientId string

@description('The client secret of the Microsoft Entra application (used for user authentication)')
@secure()
param clientSecret string

@description('The AzGovViz management group ID')
param managementGroupId string

@description('The authorized user object ID to access the web app')
param authorizedUserId string

@description('Log Analytics Workspace name for Application Insights')
param logAnalyticsWorkspaceName string = 'law-${webAppName}'

@description('Application Insights name')
param appInsightsName string = 'appi-${webAppName}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
  kind: kind
}

resource webApp 'Microsoft.Web/sites@2024-11-01' = {
  name: webAppName
  location: location
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      publicNetworkAccess: publicNetworkAccess
      windowsFxVersion: runtimeStack
      defaultDocuments: [
        'AzGovViz_${managementGroupId}.html'
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }

  resource authSettings 'config' = {
    name: 'authsettingsV2'
    properties: {
      globalValidation: {
        requireAuthentication: true
        redirectToProvider: 'azureActiveDirectory'
        unauthenticatedClientAction: 'RedirectToLoginPage'
      }
      login: {
        tokenStore: {
          enabled: true
        }
      }
      identityProviders: {
        azureActiveDirectory: {
          enabled: true
          registration: {
            openIdIssuer: '${environment().authentication.loginEndpoint}/${tenantId}/v2.0'
            clientId: clientId
            clientSecretSettingName: 'AzureAdClientSecret'
          }
          validation: {
            defaultAuthorizationPolicy: {
              allowedPrincipals: {
                identities: [
                  authorizedUserId
                ]
              }
            }
          }
        }
      }
    }
  }

  resource appsettings 'config' = {
    name: 'appsettings'
    properties: {
      AzureAdClientSecret: clientSecret
      WEBSITE_AUTH_AAD_ALLOWED_TENANTS: tenantId
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
      ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
      XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    }
  }

  resource webAppPublishSettings 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: true
    }
  }
}

output webAppName string = webApp.name
output appInsightsName string = appInsights.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
