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
    # List deployments - correct endpoint is /api/v1/publisher/deployments (no trailing slash)
    $deploymentsUrl = "https://central.sonatype.com/api/v1/publisher/deployments"
    Write-Host "  Calling: $deploymentsUrl" -ForegroundColor Gray
    
    $deploymentsResponse = Invoke-RestMethod -Uri $deploymentsUrl -Headers $headers -Method Get -ErrorAction Stop
    
    # Check response structure
    if ($null -eq $deploymentsResponse) {
        Write-Host "❌ Empty response from deployments API" -ForegroundColor Red
        exit 1
    }
    
    # The response might be an array directly or wrapped in an object
    $deploymentsList = if ($deploymentsResponse -is [Array]) { 
        $deploymentsResponse 
    } elseif ($deploymentsResponse.PSObject.Properties['deployments']) {
        $deploymentsResponse.deployments
    } else {
        $deploymentsResponse
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
