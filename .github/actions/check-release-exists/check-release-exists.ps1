#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Checks if release version already exists in GitHub Packages and Git tags

.PARAMETER ReleaseVersion
    The release version to check

.PARAMETER GitHubToken
    GitHub token for API access

.PARAMETER Repository
    GitHub repository (owner/repo)

.EXAMPLE
    .\check-release-exists.ps1 -ReleaseVersion "1.0.5" -GitHubToken $token -Repository "optivem/optivem-test-java"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion,
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$false)]
    [string]$Repository
)

Write-Host "🔍 Checking if release version $ReleaseVersion already exists..." -ForegroundColor Yellow

# Check GitHub Packages (only if token provided)
if ($GitHubToken -and $Repository) {
    $headers = @{
        'Authorization' = "Bearer $GitHubToken"
        'Accept' = 'application/vnd.github.v3+json'
    }
    
    try {
        $response = Invoke-WebRequest -Uri "https://api.github.com/repos/$Repository/packages/maven/com.optivem.optivem-test/versions" -Headers $headers -Method Get
        if ($response.StatusCode -eq 200) {
            $versions = $response.Content | ConvertFrom-Json
            $exists = $versions | Where-Object { $_.name -eq $ReleaseVersion }
            
            if ($exists) {
                Write-Host "❌ Release version $ReleaseVersion already exists in GitHub Packages!" -ForegroundColor Red
                Write-Host "Cannot promote RC to an existing release version." -ForegroundColor Red
                exit 1
            }
        }
    } catch {
        Write-Host "⚠️  Could not check GitHub Packages (may not exist yet)" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Skipping GitHub Packages check (no token/repository provided)" -ForegroundColor Yellow
}

# Check if Git tag already exists
$tagExists = git rev-parse "v$ReleaseVersion" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "❌ Git tag v$ReleaseVersion already exists!" -ForegroundColor Red
    Write-Host "That version is already claimed. Consider incrementing to the next version." -ForegroundColor Yellow
    Write-Host "To reuse this version, delete the tag first: git tag -d v$ReleaseVersion && git push origin :refs/tags/v$ReleaseVersion" -ForegroundColor Cyan
    exit 1
}

Write-Host "✅ Release version $ReleaseVersion is available for use." -ForegroundColor Green
exit 0