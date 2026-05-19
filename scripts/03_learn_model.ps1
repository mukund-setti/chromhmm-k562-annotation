<#
.SYNOPSIS
    Learns a multivariate HMM with ChromHMM LearnModel.

.DESCRIPTION
    Trains on data/binarized/ and writes model output to
    models/K562_<N>state/ (default N=15, assembly hg38).

.PARAMETER NumStates
    Number of chromatin states (default 15). Try 10, 18, or 25 for comparison.

.EXAMPLE
    .\scripts\03_learn_model.ps1
    .\scripts\03_learn_model.ps1 -NumStates 18
#>

param(
    [int]$NumStates = 15
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "C:\Users\mukun\chromhmm-project"
$Jar = Join-Path $ProjectRoot "ChromHMM\ChromHMM\ChromHMM.jar"
$BinarizedDir = Join-Path $ProjectRoot "data\binarized"
$ModelDir = Join-Path $ProjectRoot "models\K562_${NumStates}state"
$Assembly = "hg38"

Write-Host "=== LearnModel (03_learn_model.ps1) ===" -ForegroundColor Cyan
Write-Host "Binarized input: $BinarizedDir"
Write-Host "Model output:    $ModelDir"
Write-Host "Num states:      $NumStates"
Write-Host "Assembly:        $Assembly"

if (-not (Test-Path $Jar)) {
    Write-Host "ERROR: ChromHMM.jar missing. Run .\scripts\01_setup.ps1 first." -ForegroundColor Red
    exit 1
}

$hasBinarized = Get-ChildItem -Path $BinarizedDir -Filter "K562_*" -ErrorAction SilentlyContinue
if (-not $hasBinarized) {
    Write-Host "ERROR: No binarized K562_* files in $BinarizedDir. Run .\scripts\02_binarize.ps1 first." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ModelDir)) {
    New-Item -ItemType Directory -Path $ModelDir -Force | Out-Null
}

Write-Host "`nRunning LearnModel (this may take many hours)..."
& java -mx4000M -jar $Jar LearnModel $BinarizedDir $ModelDir $NumStates $Assembly
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$emissions = Join-Path $ModelDir "emissions_$NumStates.txt"
$segments = Get-ChildItem -Path $ModelDir -Filter "*_${NumStates}_segments.bed" -ErrorAction SilentlyContinue

if (Test-Path $emissions) {
    Write-Host "`nOK: Emissions matrix: $emissions" -ForegroundColor Green
} else {
    Write-Host "`nWARNING: emissions_$NumStates.txt not found." -ForegroundColor Yellow
}

if ($segments) {
    Write-Host "OK: Segmentation BED: $($segments[0].FullName)" -ForegroundColor Green
} else {
    Write-Host "WARNING: *_${NumStates}_segments.bed not found yet." -ForegroundColor Yellow
}

Write-Host "`nNext: .\scripts\04_overlap_enrichment.ps1" -ForegroundColor Green
