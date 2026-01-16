#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Checks if version already exists in GitHub Packages

.PARAMETER ReleaseVersion
    The release version to check

.PARAMETER GitHubToken
    GitHub token for API access

.PARAMETER Repository
    GitHub repository (owner/repo)

.EXAMPLE
    .\check-version-exists.ps1 -ReleaseVersion "1.0.5" -GitHubToken $token -Repository "optivem/optivem-testing-java"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion,
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$false)]
    [string]$Repository
)

Write-Host "📦 Checking if version $ReleaseVersion exists in GitHub Packages..." -ForegroundColor Blue

# Check GitHub Packages (only if token provided)
if ($GitHubToken -and $Repository) {
    $headers = @{
        'Authorization' = "Bearer $GitHubToken"
        'Accept' = 'application/vnd.github.v3+json'
    }
    
    try {
        $response = Invoke-WebRequest -Uri "https://api.github.com/repos/$Repository/packages/maven/com.optivem.optivem-testing/versions" -Headers $headers -Method Get
        if ($response.StatusCode -eq 200) {
            $versions = $response.Content | ConvertFrom-Json
            $exists = $versions | Where-Object { $_.name -eq $ReleaseVersion }
            
            if ($exists) {
                Write-Host "❌ Version $ReleaseVersion already exists in GitHub Packages!" -ForegroundColor Red
                Write-Host "Cannot promote RC to an existing release version." -ForegroundColor Red
                Write-Host "To reuse this version, delete the package first via GitHub web interface:" -ForegroundColor Cyan
                Write-Host "  https://github.com/$Repository/packages" -ForegroundColor White
                exit 1
            } else {
                Write-Host "✅ Version $ReleaseVersion not found in GitHub Packages" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "⚠️  Could not check GitHub Packages (may not exist yet)" -ForegroundColor Yellow
        Write-Host "Assuming no packages exist - proceeding..." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Skipping GitHub Packages check (no token/repository provided)" -ForegroundColor Yellow
}

exit 0