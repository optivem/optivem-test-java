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
    @{ Name = "optivem-test-${RcVersion}.jar"; Required = $true },
    @{ Name = "optivem-test-${RcVersion}-sources.jar"; Required = $false }, 
    @{ Name = "optivem-test-${RcVersion}-javadoc.jar"; Required = $false }
)

$downloadedCount = 0
$requiredCount = ($artifacts | Where-Object { $_.Required }).Count

foreach ($artifact in $artifacts) {
    $url = "$baseUrl/$($artifact.Name)"
    $outputPath = "temp-artifacts\$($artifact.Name)"
    
    Write-Host "⬇️ Downloading $($artifact.Name)..." -ForegroundColor Yellow
    
    try {
        Invoke-WebRequest -Uri $url -Headers $authHeader -OutFile $outputPath -ErrorAction Stop
        Write-Host "✅ Downloaded $($artifact.Name)" -ForegroundColor Green
        $downloadedCount++
    } catch {
        if ($artifact.Required) {
            Write-Host "❌ Failed to download required artifact $($artifact.Name): $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        } else {
            Write-Host "⚠️ Optional artifact $($artifact.Name) not available (skipped)" -ForegroundColor Yellow
        }
    }
}

if ($downloadedCount -eq 0) {
    Write-Host "❌ No artifacts were downloaded" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Downloaded $downloadedCount artifact(s) successfully" -ForegroundColor Green