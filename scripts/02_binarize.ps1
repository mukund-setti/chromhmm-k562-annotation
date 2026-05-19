<#
.SYNOPSIS
    Binarizes ENCODE BAMs with ChromHMM BinarizeBam.

.DESCRIPTION
    Reads BAMs and data/raw/cellmarkfiletable.txt, writes binarized
    chromosome files under data/binarized/ (prefix: K562).

.EXAMPLE
    .\scripts\02_binarize.ps1
#>

$ErrorActionPreference = "Stop"
$ProjectRoot = "C:\Users\mukun\chromhmm-project"
$Jar = Join-Path $ProjectRoot "ChromHMM\ChromHMM\ChromHMM.jar"
$RawDir = Join-Path $ProjectRoot "data\raw"
$BinarizedDir = Join-Path $ProjectRoot "data\binarized"
$CellMarkTable = Join-Path $RawDir "cellmarkfiletable.txt"
$Prefix = Join-Path $BinarizedDir "K562"

Write-Host "=== BinarizeBam (02_binarize.ps1) ===" -ForegroundColor Cyan
Write-Host "Input BAMs:     $RawDir"
Write-Host "Mark table:     $CellMarkTable"
Write-Host "Output prefix:  $Prefix"

if (-not (Test-Path $Jar)) {
    Write-Host "ERROR: ChromHMM.jar missing. Run .\scripts\01_setup.ps1 first." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $CellMarkTable)) {
    Write-Host "ERROR: cellmarkfiletable.txt not found." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $BinarizedDir)) {
    New-Item -ItemType Directory -Path $BinarizedDir -Force | Out-Null
}

Write-Host "`nRunning BinarizeBam (this may take hours)..."
& java -mx4000M -jar $Jar BinarizeBam $RawDir $CellMarkTable $Prefix
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$binFiles = Get-ChildItem -Path $BinarizedDir -Filter "K562_*" -ErrorAction SilentlyContinue
if ($binFiles.Count -gt 0) {
    Write-Host "`nOK: Found $($binFiles.Count) binarized file(s) under $BinarizedDir" -ForegroundColor Green
    $binFiles | Select-Object -First 5 | ForEach-Object { Write-Host "  $($_.Name)" }
} else {
    Write-Host "`nWARNING: No K562_* binarized files found yet. Check ChromHMM log output." -ForegroundColor Yellow
}

Write-Host "`nNext: .\scripts\03_learn_model.ps1" -ForegroundColor Green
