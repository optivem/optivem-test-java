#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Downloads RC artifacts from GitHub Packages

.PARAMETER RcVersion
    The RC version to download

.PARAMETER GitHubUsername
    GitHub username for authentication

.PARAMETER GitHubToken
    GitHub token for authentication

.PARAMETER Repository
    GitHub repository (owner/repo)

.EXAMPLE
    .\download-rc-artifacts.ps1 -RcVersion "1.0.5-rc.47" -GitHubUsername "user" -GitHubToken $token -Repository "optivem/optivem-testing-java"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RcVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$true)]
    [string]$Repository
)

Write-Host "📥 Downloading RC artifacts from GitHub Packages..." -ForegroundColor Blue
New-Item -ItemType Directory -Path "temp-artifacts" -Force | Out-Null

# GitHub Packages Maven repository base URL
$baseUrl = "https://maven.pkg.github.com/$Repository/com/optivem/optivem-testing/$RcVersion"
$authHeader = @{
    "Authorization" = "Bearer $GitHubToken"
}

$artifacts = @(
    "optivem-testing-${RcVersion}.jar",
    "optivem-testing-${RcVersion}-sources.jar", 
    "optivem-testing-${RcVersion}-javadoc.jar"
)

foreach ($artifact in $artifacts) {
    $url = "$baseUrl/$artifact"
    $outputPath = "temp-artifacts\$artifact"
    
    Write-Host "⬇️ Downloading $artifact..." -ForegroundColor Yellow
    
    $maxRetries = 3
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            Invoke-WebRequest -Uri $url -Headers $authHeader -OutFile $outputPath -ErrorAction Stop
            Write-Host "✅ Downloaded $artifact" -ForegroundColor Green
            $success = $true
        } catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "⚠️ Attempt $retryCount failed, retrying in 5 seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            } else {
                Write-Host "❌ Failed to download required artifact $artifact after $maxRetries attempts: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "💡 Ensure your RC build publishes sources and javadoc JARs to GitHub Packages" -ForegroundColor Cyan
                exit 1
            }
        }
    }
}

Write-Host "✅ All artifacts downloaded successfully" -ForegroundColor Green