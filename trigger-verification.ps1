#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Manual trigger script for Maven Central verification workflow

.DESCRIPTION
    Triggers the Maven Central verification workflow using GitHub CLI
    or provides instructions for manual triggering via web interface.

.PARAMETER Version
    The version to verify on Maven Central (required)

.PARAMETER DelayMinutes
    Minutes to wait before verification (default: 30)

.EXAMPLE
    .\trigger-verification.ps1 -Version "1.0.5-alpha.1"
    
.EXAMPLE
    .\trigger-verification.ps1 -Version "1.0.5-alpha.1" -DelayMinutes 45
    
.EXAMPLE
    pwsh trigger-verification.ps1 1.0.5-alpha.1 45
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Version,
    
    [Parameter(Position=1)]
    [int]$DelayMinutes = 30
)

# Display trigger information
Write-Host "🚀 Triggering Maven Central verification for version: $Version" -ForegroundColor Green
Write-Host "⏱️  Delay: $DelayMinutes minutes" -ForegroundColor Cyan

# Get current repository info
try {
    $remoteUrl = git remote get-url origin 2>$null
    if ($remoteUrl -match 'github\.com[:/]([^/]+/[^/]+)(\.git)?$') {
        $repo = $matches[1] -replace '\.git$', ''
        Write-Host "📍 Repository: $repo" -ForegroundColor Yellow
    } else {
        $repo = "optivem/optivem-test-java"  # fallback
    }
} catch {
    $repo = "optivem/optivem-test-java"  # fallback
    Write-Host "⚠️  Could not determine repository, using default: $repo" -ForegroundColor Yellow
}

# Check if GitHub CLI is available
$ghCliAvailable = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)

if ($ghCliAvailable) {
    Write-Host "Using GitHub CLI..." -ForegroundColor Blue
    
    try {
        gh workflow run maven-central-verification.yml -f version="$Version" -f delay_minutes="$DelayMinutes"
        Write-Host "✅ Workflow triggered via GitHub CLI" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to trigger workflow via GitHub CLI: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please check your GitHub CLI authentication and try again." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ GitHub CLI not found. Please install it or use the GitHub web interface." -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual trigger via web interface:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://github.com/$repo/actions/workflows/maven-central-verification.yml" -ForegroundColor White
    Write-Host "2. Click 'Run workflow'" -ForegroundColor White
    Write-Host "3. Enter version: $Version" -ForegroundColor White
    Write-Host "4. Enter delay: $DelayMinutes" -ForegroundColor White
    Write-Host ""
    Write-Host "To install GitHub CLI:" -ForegroundColor Cyan
    Write-Host "• Windows: winget install --id GitHub.cli" -ForegroundColor White
    Write-Host "• macOS: brew install gh" -ForegroundColor White
    Write-Host "• Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md" -ForegroundColor White
}