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

# Get the latest deployment ID for this version
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${SonatypeUsername}:${SonatypePassword}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Accept" = "application/json"
}

Write-Host "🔍 Finding deployment for version $ReleaseVersion..." -ForegroundColor Yellow
$deploymentsResponse = Invoke-RestMethod -Uri "https://central.sonatype.com/api/v1/publisher/deployments" -Headers $headers -Method Get

$deployment = $deploymentsResponse.deployments | Where-Object { $_.name -like "*$ReleaseVersion*" } | Select-Object -First 1

if (-not $deployment) {
    Write-Host "❌ Could not find deployment for version $ReleaseVersion" -ForegroundColor Red
    Write-Host "Available deployments:" -ForegroundColor Yellow
    $deploymentsResponse.deployments | Select-Object -First 5 | ForEach-Object { Write-Host "  - $($_.name) (Status: $($_.deploymentState))" }
    exit 1
}

$deploymentId = $deployment.deploymentId
$deploymentState = $deployment.deploymentState
Write-Host "✅ Found deployment: $deploymentId (Status: $deploymentState)" -ForegroundColor Green

if ($deploymentState -eq "PUBLISHED") {
    Write-Host "ℹ️ Deployment already published" -ForegroundColor Cyan
    exit 0
}

# Publish the deployment
Write-Host "🚀 Publishing deployment $deploymentId..." -ForegroundColor Blue
$publishResponse = Invoke-RestMethod -Uri "https://central.sonatype.com/api/v1/publisher/deployment/$deploymentId" -Headers $headers -Method Post

Write-Host "✅ Deployment published successfully!" -ForegroundColor Green
Write-Host "🔗 View at: https://central.sonatype.com/publishing/deployments" -ForegroundColor Cyan
