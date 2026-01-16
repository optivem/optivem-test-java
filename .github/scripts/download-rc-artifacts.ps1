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

# Create temporary Gradle build file
$gradleContent = @"
repositories {
    maven {
        url = uri("https://maven.pkg.github.com/$Repository")
        credentials {
            username = project.findProperty("gpr.user") ?: System.getenv("GITHUB_USERNAME")
            password = project.findProperty("gpr.key") ?: System.getenv("GITHUB_READ_PACKAGES_TOKEN")
        }
    }
}

configurations {
    rcArtifacts
}

dependencies {
    rcArtifacts 'com.optivem:optivem-test:$RcVersion'
    rcArtifacts 'com.optivem:optivem-test:$RcVersion:sources'
    rcArtifacts 'com.optivem:optivem-test:$RcVersion:javadoc'
}

task downloadRcArtifacts(type: Copy) {
    from configurations.rcArtifacts
    into 'temp-artifacts'
}
"@

$gradleContent | Out-File -FilePath "temp-download.gradle" -Encoding utf8

# Set environment variables for Gradle
$env:GITHUB_USERNAME = $GitHubUsername
$env:GITHUB_READ_PACKAGES_TOKEN = $GitHubToken

try {
    Write-Host "Using ./gradlew" -ForegroundColor Cyan
    & "./gradlew" -b temp-download.gradle downloadRcArtifacts
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to download artifacts (exit code: $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Artifacts downloaded successfully" -ForegroundColor Green
    
} finally {
    # Clean up temporary file
    if (Test-Path "temp-download.gradle") {
        Remove-Item "temp-download.gradle"
    }
}