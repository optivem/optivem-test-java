#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Creates and pushes a Git tag for a release

.PARAMETER ReleaseVersion
    The release version to tag

.PARAMETER RcVersion
    The RC version that was promoted

.EXAMPLE
    .\create-git-tag.ps1 -ReleaseVersion "1.0.5" -RcVersion "1.0.5-rc.47"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$RcVersion
)

Write-Host "🏷️ Creating Git tag v${ReleaseVersion}..." -ForegroundColor Blue

# Configure git user
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

# Create annotated tag
git tag -a "v${ReleaseVersion}" -m "Release ${ReleaseVersion} (promoted from ${RcVersion})"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create tag" -ForegroundColor Red
    exit 1
}

# Push tag to remote
git push origin "v${ReleaseVersion}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to push tag" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Git tag v${ReleaseVersion} created and pushed successfully" -ForegroundColor Green
