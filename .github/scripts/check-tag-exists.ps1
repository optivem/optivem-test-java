#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Checks if Git tag already exists

.PARAMETER ReleaseVersion
    The release version to check (tag will be v{version})

.EXAMPLE
    .\check-tag-exists.ps1 -ReleaseVersion "1.0.5"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion
)

Write-Host "🏷️  Checking if Git tag v$ReleaseVersion already exists..." -ForegroundColor Blue

# Fetch remote tags first (GitHub Actions has shallow clone by default)
Write-Host "📡 Fetching remote tags..." -ForegroundColor Cyan
git fetch origin --tags 2>$null

# Check if Git tag already exists (locally or remotely)
$tagExists = git rev-parse "v$ReleaseVersion" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "❌ Git tag v$ReleaseVersion already exists!" -ForegroundColor Red
    Write-Host "That version is already claimed. Consider incrementing to the next version." -ForegroundColor Yellow
    Write-Host "To reuse this version, delete the tag first: git tag -d v$ReleaseVersion && git push origin :refs/tags/v$ReleaseVersion" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host "✅ Git tag v$ReleaseVersion does not exist" -ForegroundColor Green
}

exit 0