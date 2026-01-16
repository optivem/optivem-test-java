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
    [string]$ReleaseVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypeUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypePassword
)

Write-Host "📤 Publishing deployment on Maven Central..." -ForegroundColor Blue

# Set up authentication headers
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${SonatypeUsername}:${SonatypePassword}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Accept" = "application/json"
}

Write-Host "🔍 Finding deployment for version $ReleaseVersion..." -ForegroundColor Yellow

try {
    # Try the API endpoint - Maven Central Portal uses a separate API domain
    $apiBase = "https://central.sonatype.com"
    $deploymentsUrl = "$apiBase/api/v1/publisher/deployments"
    
    Write-Host "  Attempting API call to: $deploymentsUrl" -ForegroundColor Gray
    
    # Add more headers that might be needed
    $headers["Content-Type"] = "application/json"
    
    try {
        $deploymentsResponse = Invoke-RestMethod -Uri $deploymentsUrl -Headers $headers -Method Get -ErrorAction Stop
    } catch {
        # Try alternative domain if the first fails
        Write-Host "  First attempt failed, trying api.central.sonatype.com..." -ForegroundColor Yellow
        $apiBase = "https://api.central.sonatype.com"
        $deploymentsUrl = "$apiBase/v1/publisher/deployments"
        Write-Host "  Attempting: $deploymentsUrl" -ForegroundColor Gray
        $deploymentsResponse = Invoke-RestMethod -Uri $deploymentsUrl -Headers $headers -Method Get -ErrorAction Stop
    }
    
    Write-Host "  ✓ Response received" -ForegroundColor Green
    
    # Handle different response formats
    $deploymentsList = if ($deploymentsResponse -is [Array]) { 
        $deploymentsResponse 
    } elseif ($deploymentsResponse.PSObject.Properties['deployments']) {
        $deploymentsResponse.deployments
    } elseif ($deploymentsResponse.PSObject.Properties['items']) {
        $deploymentsResponse.items
    } else {
        $deploymentsResponse
    }
    
    if ($null -eq $deploymentsList -or $deploymentsList.Count -eq 0) {
        Write-Host "⚠️  No deployments found" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Manual steps:" -ForegroundColor Cyan
        Write-Host "1. Go to: https://central.sonatype.com/publishing/deployments" -ForegroundColor White
        Write-Host "2. Find deployment for version $ReleaseVersion" -ForegroundColor White
        Write-Host "3. Click 'Publish' button" -ForegroundColor White
        exit 0
    }
    
    Write-Host "  Found $($deploymentsList.Count) total deployments" -ForegroundColor Gray
    
    # Find deployment matching the version
    $deployment = $deploymentsList | Where-Object { 
        $_.name -like "*$ReleaseVersion*" -or 
        ($_.PSObject.Properties['version'] -and $_.version -eq $ReleaseVersion)
    } | Sort-Object -Property { 
        if ($_.PSObject.Properties['createdDate']) { $_.createdDate } 
        elseif ($_.PSObject.Properties['created']) { $_.created }
        else { Get-Date }
    } -Descending | Select-Object -First 1

    if (-not $deployment) {
        Write-Host "❌ Could not find deployment for version $ReleaseVersion" -ForegroundColor Red
        Write-Host "Recent deployments:" -ForegroundColor Yellow
        $deploymentsList | Select-Object -First 5 | ForEach-Object { 
            $name = if ($_.PSObject.Properties['name']) { $_.name } else { $_.deploymentId }
            $state = if ($_.PSObject.Properties['deploymentState']) { $_.deploymentState } 
                     elseif ($_.PSObject.Properties['state']) { $_.state } 
                     else { 'UNKNOWN' }
            Write-Host "  - $name (Status: $state)" 
        }
        exit 1
    }

    $deploymentId = if ($deployment.PSObject.Properties['deploymentId']) { 
        $deployment.deploymentId 
    } else { 
        $deployment.id 
    }
    
    $deploymentState = if ($deployment.PSObject.Properties['deploymentState']) { 
        $deployment.deploymentState 
    } elseif ($deployment.PSObject.Properties['state']) { 
        $deployment.state 
    } else { 
        'UNKNOWN' 
    }
    
    Write-Host "✅ Found deployment: $deploymentId (Status: $deploymentState)" -ForegroundColor Green

    if ($deploymentState -eq "PUBLISHED") {
        Write-Host "ℹ️ Deployment already published" -ForegroundColor Cyan
        exit 0
    }

    # Publish the deployment
    Write-Host "🚀 Publishing deployment $deploymentId..." -ForegroundColor Blue
    $publishUrl = "https://central.sonatype.com/api/v1/publisher/deployment/$deploymentId"
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
