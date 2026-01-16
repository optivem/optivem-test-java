#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Finds the latest RC version from GitHub Packages if no version is provided

.PARAMETER RcVersion
    RC version to use (optional - if empty, will find latest)

.PARAMETER GitHubToken
    GitHub token for API access

.PARAMETER Repository
    GitHub repository (owner/repo)

.PARAMETER PackageName
    Package name in GitHub Packages

.EXAMPLE
    .\find-latest-rc-version.ps1 -GitHubToken $token -Repository "optivem/optivem-test-java"
    .\find-latest-rc-version.ps1 -RcVersion "1.0.5-rc.47" -GitHubToken $token -Repository "optivem/optivem-test-java"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$RcVersion = "",
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$true)]
    [string]$Repository,
    
    [Parameter(Mandatory=$false)]
    [string]$PackageName = "com.optivem.optivem-test"
)

if ([string]::IsNullOrWhiteSpace($RcVersion)) {
    Write-Host "🔍 No RC version provided, finding latest RC version..." -ForegroundColor Blue
    
    # Call GitHub API to get latest RC version
    $headers = @{
        "Authorization" = "Bearer $GitHubToken"
        "Accept" = "application/vnd.github+json"
    }
    
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/packages/maven/$PackageName/versions" -Headers $headers
    
    $rcVersions = $response | Where-Object { $_.name -like "*-rc.*" } | Sort-Object { [datetime]$_.created_at } -Descending
    
    if ($rcVersions.Count -eq 0) {
        Write-Host "❌ No RC versions found in GitHub Packages" -ForegroundColor Red
        exit 1
    }
    
    $latestRc = $rcVersions[0].name
    Write-Host "✅ Found latest RC version: $latestRc" -ForegroundColor Green
    echo "rc-version=$latestRc" >> $env:GITHUB_OUTPUT
} else {
    Write-Host "📋 Using provided RC version: $RcVersion" -ForegroundColor Green
    echo "rc-version=$RcVersion" >> $env:GITHUB_OUTPUT
}