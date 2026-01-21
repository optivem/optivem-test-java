param(
    [Parameter(Mandatory=$true)]
    [string]$CheckScript,
    
    [Parameter(Mandatory=$false)]
    [string]$ScriptArgs = "",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxAttempts = 30,
    
    [Parameter(Mandatory=$false)]
    [int]$PollInterval = 10,
    
    [Parameter(Mandatory=$false)]
    [string]$ConditionName = "condition"
)

Write-Host "⏳ Polling until $ConditionName is met..." -ForegroundColor Blue
Write-Host "   Check script: $CheckScript" -ForegroundColor Gray
Write-Host "   Max attempts: $MaxAttempts" -ForegroundColor Gray
Write-Host "   Poll interval: ${PollInterval}s" -ForegroundColor Gray
Write-Host ""

$attempt = 0
$conditionMet = $false

# Resolve script path relative to the action directory
$actionDir = Split-Path -Parent $PSCommandPath
$scriptPath = Join-Path $actionDir $CheckScript

if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Check script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

while ($attempt -lt $MaxAttempts) {
    $attempt++
    
    Write-Host "[$attempt/$MaxAttempts] Checking $ConditionName..." -ForegroundColor Yellow
    
    try {
        # Execute the check script with arguments
        if ($ScriptArgs) {
            $argArray = $ScriptArgs -split ' '
            & $scriptPath @argArray
        } else {
            & $scriptPath
        }
        
        # Check exit code:
        # 0 = condition met (success)
        # 1 = permanent failure (stop polling)
        # 2 = still waiting (continue polling)
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Condition met: $ConditionName" -ForegroundColor Green
            $conditionMet = $true
            break
        } elseif ($LASTEXITCODE -eq 1) {
            Write-Host ""
            Write-Host "❌ Permanent failure detected, stopping polling" -ForegroundColor Red
            exit 1
        }
        # Exit code 2 means keep polling
        
    } catch {
        Write-Host "   ⚠️  Error running check script: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    if ($attempt -lt $MaxAttempts -and -not $conditionMet) {
        Write-Host "   Waiting ${PollInterval}s before next check..." -ForegroundColor Gray
        Start-Sleep -Seconds $PollInterval
    }
}

if (-not $conditionMet) {
    Write-Host ""
    Write-Host "❌ Timed out waiting for '$ConditionName' after $MaxAttempts attempts" -ForegroundColor Red
    exit 1
}
