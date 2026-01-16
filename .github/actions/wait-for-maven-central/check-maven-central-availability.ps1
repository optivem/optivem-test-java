#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Check if artifact is available on Maven Central
.DESCRIPTION
    Returns exit code 0 if artifact exists on repo1.maven.org, non-zero otherwise
.PARAMETER Version
    The version to check
.PARAMETER GroupId
    Maven group ID (default: com.optivem)
.PARAMETER ArtifactId
    Maven artifact ID (default: optivem-test)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$true)]
    [string]$GroupId,
    
    [Parameter(Mandatory=$true)]
    [string]$ArtifactId
)

$groupPath = $GroupId.Replace('.', '/')
$pomUrl = "https://repo1.maven.org/maven2/$groupPath/$ArtifactId/$Version/$ArtifactId-$Version.pom"

try {
    $response = Invoke-WebRequest -Uri $pomUrl -Method Head -ErrorAction Stop
    
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Artifact available on Maven Central" -ForegroundColor Green
        exit 0  # Success
    }
    
    Write-Host "   ⏳ Not yet available (HTTP $($response.StatusCode))" -ForegroundColor Gray
    exit 2
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "   ⏳ Not yet available (HTTP $statusCode)" -ForegroundColor Gray
    exit 2
}
