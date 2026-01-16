# Maven Central Manual Verification

This document explains how the manual Maven Central verification system works.

## Overview

Due to Maven Central's manual publishing process via Central Portal, we use a manual verification approach:

1. **Upload** bundle to Central Portal during commit stage
2. **Manually publish** in Central Portal when ready (could be days later)  
3. **Manually trigger** verification after publishing
4. **Verify** availability and report results

## Architecture

```
Commit Stage → Upload Bundle → Manual Publish → Manual Verification
                                   ↓ (days later)     ↓ (30+ min delay)
                               Central Portal → Run Smoke Tests → Report
```

## Workflows

### 1. Commit Stage (`commit-stage.yml`)
- Builds and publishes to GitHub Packages (immediate)
- Uploads bundle to Central Portal (ready for manual publishing)
- **Displays** next steps for manual publishing

### 2. Manual Publishing
- Login to [Central Portal](https://central.sonatype.com/publishing/deployments)
- Review and publish uploaded bundle
- Can be done days/weeks after upload

### 3. Maven Central Verification (`maven-central-verification.yml`)
- **Manually triggered** after Central Portal publishing
- **Waits** configurable delay (default: 30 minutes)
- **Runs** appropriate smoke tests based on version type

## Triggering Methods

### Manual Trigger (Primary Method)
After manually publishing in Central Portal, trigger verification:

Using PowerShell script:
```powershell
# Simple trigger
.\trigger-verification.ps1 -Version "1.0.5-alpha.1"

# With custom delay
.\trigger-verification.ps1 -Version "1.0.5-alpha.1" -DelayMinutes 45

# Positional parameters
.\trigger-verification.ps1 1.0.5-alpha.1 45
```
Using GitHub CLI directly:
```powershell
gh workflow run maven-central-verification.yml -f version="1.0.5-alpha.1" -f delay_minutes="30"
```

Using GitHub web interface:
1. Go to Actions → Maven Central Verification  
2. Click "Run workflow"
3. Enter version and delay

## Workflow Steps

### 1. Upload Bundle (Commit Stage)
```
./gradlew core:uploadToCentralPortal → Bundle ready in Central Portal
```

### 2. Manual Publish (Central Portal)
```
Login → Review Bundle → Click Publish → Wait for propagation
```

### 3. Trigger Verification (Manual)  
```
.\trigger-verification.ps1 -Version "X.Y.Z" → Workflow starts → Tests run
```

## Smoke Tests

### RC Versions (`smoke-test-rc-mavencentral`)
- Tests RC versions (e.g., `1.0.5-rc.123`)
- Uses Maven Central repository
- Expects version parameter: `-Pversion=1.0.5-rc.123`

### Release Versions (`smoke-test-release-mavencentral`) 
- Tests release versions (e.g., `1.0.5`)
- Uses Maven Central repository
- Expects version parameter: `-Pversion=1.0.5`

## Benefits

1. **Non-blocking**: Main CI pipeline completes quickly
2. **Flexible**: Configurable delays for different scenarios
3. **Reliable**: Dedicated verification with proper error handling
4. **Scalable**: Can be triggered multiple times for different versions
5. **Observable**: Clear success/failure reporting

## Configuration

### Environment Variables
- No additional secrets required (uses existing `GITHUB_TOKEN`)
- Inherits JDK and Gradle setup from standard workflows

### Timing
- **Default delay**: 35 minutes (safe for most publications)
- **Minimum recommended**: 30 minutes
- **Maximum practical**: 90 minutes
- **Configurable**: Per-trigger via `delay_minutes` parameter

## Monitoring

### Success Indicators
- ✅ Workflow completes successfully
- ✅ Smoke tests pass
- ✅ Dependencies resolve from Maven Central

### Failure Scenarios  
- ❌ Version not yet available (try longer delay)
- ❌ Network/Maven Central issues (retry)
- ❌ Test failures (check artifact integrity)

## Troubleshooting

### Version not found after delay
1. Check Central Portal status: https://central.sonatype.com/
2. Verify publication was successful in commit-stage logs
3. Try manual trigger with longer delay (60+ minutes)

### Workflow not triggering automatically
1. Check commit-stage workflow completed successfully
2. Verify `GITHUB_TOKEN` has repository dispatch permissions
3. Check webhook delivery in repository settings

### Tests failing unexpectedly
1. Verify version format matches expectations
2. Check Maven Central metadata: `https://repo1.maven.org/maven2/com/optivem/optivem-testing/maven-metadata.xml`
3. Test locally with same version: `./gradlew system-test:smoke-test-*-mavencentral:test -Pversion=X.Y.Z`

## Future Enhancements

1. **Central Portal Webhooks**: Replace manual triggering with official notifications
2. **Slack/Teams Integration**: Real-time status updates
3. **Retry Logic**: Automatic retries with exponential backoff
4. **Health Checks**: Regular verification of published versions
5. **Metrics**: Track publication timing and success rates