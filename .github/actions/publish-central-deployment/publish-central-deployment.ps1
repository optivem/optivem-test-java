#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Publishes a deployment on Maven Central Portal via REST API

.PARAMETER ReleaseVersion
    The release version to publish

.PARAMETER SonatypeUsername
    Sonatype username

.PARAMETER SonatypePassword
    Sonatype password

.EXAMPLE
    .\publish-central-deployment.ps1 -ReleaseVersion "1.0.5" -SonatypeUsername "user" -SonatypePassword "pass"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$DeploymentId,
    
    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypeUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypePassword
)

Write-Host "📤 Publishing deployment on Maven Central..." -ForegroundColor Blue

# Set up authentication headers - Maven Central Portal API uses Bearer token, not Basic auth
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${SonatypeUsername}:${SonatypePassword}"))
$headers = @{
    "Authorization" = "Bearer $auth"
    "Accept" = "application/json"
}

Write-Host "🔍 Checking deployment status for ID: $DeploymentId..." -ForegroundColor Yellow

try {
    # Check deployment status using the correct API endpoint
    # https://central.sonatype.org/publish/publish-portal-api/
    $apiBase = "https://central.sonatype.com"
    $statusUrl = "$apiBase/api/v1/publisher/status?id=$DeploymentId"
    
    Write-Host "  Calling: $statusUrl" -ForegroundColor Gray
    
    $statusResponse = Invoke-RestMethod -Uri $statusUrl -Headers $headers -Method Post -ErrorAction Stop
    
    Write-Host "  Status: $($statusResponse.deploymentState)" -ForegroundColor Gray
    
    # Check if deployment is in VALIDATED state (ready to publish)
    if ($statusResponse.deploymentState -ne "VALIDATED") {
        Write-Host "⚠️  Deployment is not in VALIDATED state" -ForegroundColor Yellow
        Write-Host "  Current state: $($statusResponse.deploymentState)" -ForegroundColor Yellow
        
        if ($statusResponse.deploymentState -eq "PENDING" -or $statusResponse.deploymentState -eq "VALIDATING") {
            Write-Host "⏳ Deployment is still validating. Please wait and try again." -ForegroundColor Yellow
        } elseif ($statusResponse.deploymentState -eq "FAILED") {
            Write-Host "❌ Deployment validation failed" -ForegroundColor Red
            if ($statusResponse.PSObject.Properties['errors']) {
                Write-Host "Errors:" -ForegroundColor Red
                $statusResponse.errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
            }
            exit 1
        } elseif ($statusResponse.deploymentState -eq "PUBLISHED") {
            Write-Host "✅ Deployment already published!" -ForegroundColor Green
            exit 0
        }
        exit 1
    }
    
    Write-Host "✅ Deployment validated and ready to publish" -ForegroundColor Green

    # Publish the deployment
    Write-Host "🚀 Publishing deployment $DeploymentId..." -ForegroundColor Blue
    $publishUrl = "$apiBase/api/v1/publisher/deployment/$DeploymentId"
    Write-Host "  Calling: $publishUrl" -ForegroundColor Gray
    
    $publishResponse = Invoke-RestMethod -Uri $publishUrl -Headers $headers -Method Post -ErrorAction Stop

    Write-Host "✅ Deployment published successfully!" -ForegroundColor Green
    Write-Host "🔗 View at: https://central.sonatype.com/publishing/deployments" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ API Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
    }
    if ($_.ErrorDetails.Message) {
        Write-Host "Error Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    exit 1
}
