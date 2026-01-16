#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Creates Maven Central bundle from existing artifacts and uploads without rebuilding

.PARAMETER ReleaseVersion
    The release version to upload

.PARAMETER SonatypeUsername
    Sonatype username

.PARAMETER SonatypePassword
    Sonatype password

.PARAMETER GpgPrivateKey
    GPG private key for signing

.PARAMETER GpgPassphrase
    GPG passphrase

.EXAMPLE
    .\upload-to-maven-central.ps1 -ReleaseVersion "1.0.5" -SonatypeUsername "user" -SonatypePassword "pass" -GpgPrivateKey $key -GpgPassphrase $phrase
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypeUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$SonatypePassword,
    
    [Parameter(Mandatory=$true)]
    [string]$GpgPrivateKey,
    
    [Parameter(Mandatory=$true)]
    [string]$GpgPassphrase,
    
    [Parameter(Mandatory=$true)]
    [string]$GroupId,
    
    [Parameter(Mandatory=$true)]
    [string]$ArtifactId,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectDescription,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$LicenseName,
    
    [Parameter(Mandatory=$true)]
    [string]$LicenseUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$DeveloperId,
    
    [Parameter(Mandatory=$true)]
    [string]$DeveloperName,
    
    [Parameter(Mandatory=$true)]
    [string]$DeveloperEmail,
    
    [Parameter(Mandatory=$true)]
    [string]$ScmConnection,
    
    [Parameter(Mandatory=$true)]
    [string]$ScmDeveloperConnection,
    
    [Parameter(Mandatory=$true)]
    [string]$ScmUrl
)

Write-Host "📦 Creating Maven Central bundle from existing artifacts..." -ForegroundColor Blue

$artifactsDir = "core/build/libs"
$bundleDir = "core/build/central-portal-bundle"
$groupPath = $GroupId -replace '\.', '/'
$mavenDir = "$bundleDir/$groupPath/$ArtifactId/$ReleaseVersion"
$bundleZip = "core/build/$ArtifactId-$ReleaseVersion.zip"

# Verify artifacts exist
$requiredFiles = @(
    "$artifactsDir/$ArtifactId-$ReleaseVersion.jar",
    "$artifactsDir/$ArtifactId-$ReleaseVersion-sources.jar",
    "$artifactsDir/$ArtifactId-$ReleaseVersion-javadoc.jar"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "❌ Missing required artifact: $file" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ All required artifacts found" -ForegroundColor Green

# Create bundle directory structure
if (Test-Path $bundleDir) {
    Remove-Item $bundleDir -Recurse -Force
}
New-Item -ItemType Directory -Path $mavenDir -Force | Out-Null

# Generate POM file from template
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pomTemplate = Join-Path $scriptDir "pom.template.xml"

if (-not (Test-Path $pomTemplate)) {
    Write-Host "❌ POM template not found: $pomTemplate" -ForegroundColor Red
    exit 1
}

$pomContent = Get-Content $pomTemplate -Raw

# Replace all placeholders
$replacements = @{
    '{{GROUP_ID}}' = $GroupId
    '{{ARTIFACT_ID}}' = $ArtifactId
    '{{VERSION}}' = $ReleaseVersion
    '{{NAME}}' = $ProjectName
    '{{DESCRIPTION}}' = $ProjectDescription
    '{{URL}}' = $ProjectUrl
    '{{LICENSE_NAME}}' = $LicenseName
    '{{LICENSE_URL}}' = $LicenseUrl
    '{{DEVELOPER_ID}}' = $DeveloperId
    '{{DEVELOPER_NAME}}' = $DeveloperName
    '{{DEVELOPER_EMAIL}}' = $DeveloperEmail
    '{{SCM_CONNECTION}}' = $ScmConnection
    '{{SCM_DEVELOPER_CONNECTION}}' = $ScmDeveloperConnection
    '{{SCM_URL}}' = $ScmUrl
}

foreach ($placeholder in $replacements.Keys) {
    $pomContent = $pomContent -replace [regex]::Escape($placeholder), $replacements[$placeholder]
}

$pomFile = "$mavenDir/$ArtifactId-$ReleaseVersion.pom"
$pomContent | Out-File -FilePath $pomFile -Encoding utf8 -NoNewline

# Copy artifacts to bundle
foreach ($file in $requiredFiles) {
    $fileName = Split-Path $file -Leaf
    Copy-Item $file "$mavenDir/$fileName"
}

Write-Host "📝 Importing GPG key..." -ForegroundColor Yellow

# Import GPG key
$gpgKeyFile = [System.IO.Path]::GetTempFileName()
$GpgPrivateKey | Out-File -FilePath $gpgKeyFile -Encoding utf8 -NoNewline

$importOutput = gpg --batch --import $gpgKeyFile 2>&1
Write-Host $importOutput

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to import GPG key" -ForegroundColor Red
    Remove-Item $gpgKeyFile -Force
    exit 1
}

Remove-Item $gpgKeyFile -Force

# Get the key ID that was just imported
$keyIdOutput = gpg --list-secret-keys --keyid-format LONG 2>&1 | Select-String -Pattern "sec.*\/([A-F0-9]+)" | Select-Object -First 1
if ($keyIdOutput) {
    $keyId = $keyIdOutput.Matches[0].Groups[1].Value
    Write-Host "✅ GPG key imported successfully (Key ID: $keyId)" -ForegroundColor Green
} else {
    Write-Host "⚠️  GPG key imported but couldn't detect Key ID" -ForegroundColor Yellow
}

Write-Host "🔐 Signing artifacts..." -ForegroundColor Yellow

# Create passphrase file for GPG
$passphraseFile = [System.IO.Path]::GetTempFileName()
$GpgPassphrase | Out-File -FilePath $passphraseFile -Encoding utf8 -NoNewline

# Sign all files
$filesToSign = @(
    "$ArtifactId-$ReleaseVersion.pom",
    "$ArtifactId-$ReleaseVersion.jar",
    "$ArtifactId-$ReleaseVersion-sources.jar",
    "$ArtifactId-$ReleaseVersion-javadoc.jar"
)

foreach ($fileName in $filesToSign) {
    $filePath = "$mavenDir/$fileName"
    
    # Verify file exists before signing
    if (-not (Test-Path $filePath)) {
        Write-Host "❌ File not found: $filePath" -ForegroundColor Red
        Remove-Item $passphraseFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    
    # Sign with GPG using passphrase file and pinentry-mode loopback
    $signOutput = gpg --batch --yes --pinentry-mode loopback --passphrase-file $passphraseFile --armor --detach-sign $filePath 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to sign $fileName" -ForegroundColor Red
        Write-Host "GPG Output: $signOutput" -ForegroundColor Red
        Remove-Item $passphraseFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    
    # Verify signature file was created
    if (-not (Test-Path "$filePath.asc")) {
        Write-Host "❌ Signature file not created for $fileName" -ForegroundColor Red
        Remove-Item $passphraseFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    
    # Generate checksums
    $fileContent = [System.IO.File]::ReadAllBytes($filePath)
    
    # MD5
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $md5Hash = [BitConverter]::ToString($md5.ComputeHash($fileContent)).Replace("-", "").ToLower()
    $md5Hash | Out-File -FilePath "$filePath.md5" -Encoding ascii -NoNewline
    
    # SHA1
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $sha1Hash = [BitConverter]::ToString($sha1.ComputeHash($fileContent)).Replace("-", "").ToLower()
    $sha1Hash | Out-File -FilePath "$filePath.sha1" -Encoding ascii -NoNewline
}

# Clean up passphrase file
Remove-Item $passphraseFile -Force -ErrorAction SilentlyContinue

Write-Host "✅ All artifacts signed and checksums generated" -ForegroundColor Green

# Create zip bundle
Write-Host "📦 Creating bundle zip..." -ForegroundColor Yellow
if (Test-Path $bundleZip) {
    Remove-Item $bundleZip -Force
}

Compress-Archive -Path "$bundleDir/*" -DestinationPath $bundleZip

Write-Host "✅ Bundle created: $bundleZip" -ForegroundColor Green

# Upload to Central Portal
Write-Host "📤 Uploading to Maven Central..." -ForegroundColor Blue

$curlArgs = @(
    '-X', 'POST',
    'https://central.sonatype.com/api/v1/publisher/upload',
    '-u', "${SonatypeUsername}:${SonatypePassword}",
    '-F', "bundle=@$bundleZip",
    '-F', 'publishingType=USER_MANAGED'
)

& curl @curlArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Upload failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Upload completed successfully!" -ForegroundColor Green
Write-Host "🔗 Check status: https://central.sonatype.com/publishing/deployments" -ForegroundColor Cyan
