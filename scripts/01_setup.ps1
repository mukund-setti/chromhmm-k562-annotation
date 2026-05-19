<#
.SYNOPSIS
    Creates project folders, downloads ChromHMM, and verifies Java.

.DESCRIPTION
    Idempotent setup for the K562 ChromHMM pipeline. Safe to re-run.
    - Ensures data/, models/, results/, scripts/, tutorial/ exist
    - Downloads ChromHMM.zip into ChromHMM/ and extracts if needed
    - Checks that java is on PATH

.EXAMPLE
    .\scripts\01_setup.ps1
#>

$ErrorActionPreference = "Stop"
$ProjectRoot = "C:\Users\mukun\chromhmm-project"
$ChromHmmDir = Join-Path $ProjectRoot "ChromHMM"
$ChromHmmZip = Join-Path $ChromHmmDir "ChromHMM.zip"
$ChromHmmUrl = "https://compbio.mit.edu/ChromHMM/ChromHMM.zip"

Write-Host "=== ChromHMM setup (01_setup.ps1) ===" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot"

$folders = @(
    (Join-Path $ProjectRoot "data\raw"),
    (Join-Path $ProjectRoot "data\binarized"),
    (Join-Path $ProjectRoot "models"),
    (Join-Path $ProjectRoot "results"),
    (Join-Path $ProjectRoot "scripts"),
    (Join-Path $ProjectRoot "tutorial"),
    $ChromHmmDir
)

foreach ($dir in $folders) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created: $dir"
    } else {
        Write-Host "Exists:  $dir"
    }
}

Write-Host "`nChecking Java..."
$javaCmd = Get-Command java -ErrorAction SilentlyContinue
if (-not $javaCmd) {
    Write-Host "ERROR: java not found on PATH. Install JDK 8+ and re-run." -ForegroundColor Red
    exit 1
}
& java -version 2>&1 | ForEach-Object { Write-Host $_ }

if (-not (Test-Path $ChromHmmZip)) {
    Write-Host "`nDownloading ChromHMM from $ChromHmmUrl ..."
    Invoke-WebRequest -Uri $ChromHmmUrl -OutFile $ChromHmmZip -UseBasicParsing
} else {
    Write-Host "`nChromHMM.zip already present."
}

$jarPath = Join-Path $ChromHmmDir "ChromHMM\ChromHMM.jar"
if (-not (Test-Path $jarPath)) {
    Write-Host "Extracting ChromHMM.zip ..."
    Expand-Archive -Path $ChromHmmZip -DestinationPath $ChromHmmDir -Force
} else {
    Write-Host "ChromHMM.jar already extracted."
}

if (Test-Path $jarPath) {
    Write-Host "`nOK: ChromHMM.jar at $jarPath" -ForegroundColor Green
} else {
    Write-Host "`nERROR: ChromHMM.jar not found after extract. Check zip contents." -ForegroundColor Red
    exit 1
}

Write-Host "`nSetup complete. Next: .\scripts\02_binarize.ps1" -ForegroundColor Green
