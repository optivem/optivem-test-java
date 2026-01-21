#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Check Maven Central deployment state
.DESCRIPTION
    Returns exit code 0 if deployment is in expected state, non-zero otherwise
.PARAMETER DeploymentId
    Maven Central deployment ID
.PARAMETER ExpectedState
    Expected state (VALIDATED, PUBLISHING, PUBLISHED)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$DeploymentId,
    
    [Parameter(Mandatory=$true)]
    [string]$ExpectedState
)

# Read credentials from environment
$username = $env:SONATYPE_USERNAME
$password = $env:SONATYPE_PASSWORD

if (-not $username -or -not $password) {
    Write-Host "   ❌ SONATYPE credentials not found in environment" -ForegroundColor Red
    exit 1
}

# Set up authentication
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))
$headers = @{
    "Authorization" = "Bearer $auth"
    "Accept" = "application/json"
}

$statusUrl = "https://central.sonatype.com/api/v1/publisher/status?id=$DeploymentId"

try {
    $response = Invoke-RestMethod -Uri $statusUrl -Headers $headers -Method Post -ErrorAction Stop
    $state = $response.deploymentState
    
    Write-Host "   Current state: $state" -ForegroundColor Cyan
    
    # Check for failure - exit 1 to stop polling immediately
    if ($state -eq "FAILED") {
        Write-Host "   ❌ Deployment failed" -ForegroundColor Red
        if ($response.PSObject.Properties['errors'] -and $response.errors) {
            $response.errors | ForEach-Object { 
                Write-Host "      • $_" -ForegroundColor Red 
            }
        }
        exit 1  # Permanent failure - stop polling
    }
    
    # Check if expected state reached
    if ($state -eq $ExpectedState) {
        exit 0  # Success - condition met
    }
    
    # Still waiting - continue polling
    exit 2
    
} catch {
    Write-Host "   ⚠️  API Error: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 2  # Transient error - continue polling
}
