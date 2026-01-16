param(
    [Parameter(Mandatory=$true)]
    [string]$DeploymentId,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypeUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypePassword,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxAttempts = 30,
    
    [Parameter(Mandatory=$false)]
    [int]$PollInterval = 10
)

Write-Host "⏳ Waiting for deployment validation..." -ForegroundColor Blue
Write-Host "   Deployment ID: $DeploymentId" -ForegroundColor Gray
Write-Host "   Max attempts: $MaxAttempts" -ForegroundColor Gray
Write-Host "   Poll interval: ${PollInterval}s" -ForegroundColor Gray
Write-Host ""

# Set up authentication headers
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${SonatypeUsername}:${SonatypePassword}"))
$headers = @{
    "Authorization" = "Bearer $auth"
    "Accept" = "application/json"
}

$apiBase = "https://central.sonatype.com"
$statusUrl = "$apiBase/api/v1/publisher/status?id=$DeploymentId"

$attempt = 0
$validated = $false

while ($attempt -lt $MaxAttempts) {
    $attempt++
    
    Write-Host "[$attempt/$MaxAttempts] Checking deployment status..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri $statusUrl -Headers $headers -Method Post -ErrorAction Stop
        
        $state = $response.deploymentState
        Write-Host "   Status: $state" -ForegroundColor Cyan
        
        switch ($state) {
            "VALIDATED" {
                Write-Host ""
                Write-Host "✅ Deployment validated successfully!" -ForegroundColor Green
                $validated = $true
                break
            }
            "PUBLISHED" {
                Write-Host ""
                Write-Host "⚠️  Deployment already in PUBLISHED state" -ForegroundColor Yellow
                Write-Host "   This means it was either:" -ForegroundColor Yellow
                Write-Host "   • Published manually via the UI" -ForegroundColor Yellow
                Write-Host "   • Already published by a previous workflow run" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "❌ Cannot proceed with automated publishing" -ForegroundColor Red
                exit 1
            }
            "FAILED" {
                Write-Host ""
                Write-Host "❌ Deployment validation failed" -ForegroundColor Red
                if ($response.PSObject.Properties['errors'] -and $response.errors) {
                    Write-Host ""
                    Write-Host "Errors:" -ForegroundColor Red
                    $response.errors | ForEach-Object { 
                        Write-Host "  • $_" -ForegroundColor Red 
                    }
                }
                exit 1
            }
            "PENDING" {
                Write-Host "   ⏳ Waiting for validation to start..." -ForegroundColor Gray
            }
            "VALIDATING" {
                Write-Host "   🔍 Validation in progress..." -ForegroundColor Gray
            }
            default {
                Write-Host "   ⚠️  Unknown state: $state" -ForegroundColor Yellow
            }
        }
        
        if ($validated) {
            break
        }
        
    } catch {
        Write-Host "   ⚠️  Error checking status: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($_.ErrorDetails.Message) {
            Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        }
    }
    
    if ($attempt -lt $MaxAttempts -and -not $validated) {
        Write-Host "   Waiting ${PollInterval}s before next check..." -ForegroundColor Gray
        Start-Sleep -Seconds $PollInterval
    }
}

if (-not $validated) {
    Write-Host ""
    Write-Host "❌ Deployment validation timed out after $MaxAttempts attempts" -ForegroundColor Red
    Write-Host "   Check status at: https://central.sonatype.com/publishing/deployments" -ForegroundColor Yellow
    exit 1
}
