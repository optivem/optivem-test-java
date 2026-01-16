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
    .\download-rc-artifacts.ps1 -RcVersion "1.0.5-rc.47" -GitHubUsername "user" -GitHubToken $token -Repository "optivem/optivem-test-java"
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
$baseUrl = "https://maven.pkg.github.com/$Repository/com/optivem/optivem-test/$RcVersion"
$authHeader = @{
    "Authorization" = "Bearer $GitHubToken"
}

$artifacts = @(
    "optivem-test-${RcVersion}.jar",
    "optivem-test-${RcVersion}-sources.jar", 
    "optivem-test-${RcVersion}-javadoc.jar"
)

foreach ($artifact in $artifacts) {
    $url = "$baseUrl/$artifact"
    $outputPath = "temp-artifacts\$artifact"
    
    Write-Host "⬇️ Downloading $artifact..." -ForegroundColor Yellow
    
    try {
        Invoke-WebRequest -Uri $url -Headers $authHeader -OutFile $outputPath -ErrorAction Stop
        Write-Host "✅ Downloaded $artifact" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download $artifact`: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ All artifacts downloaded successfully" -ForegroundColor Green