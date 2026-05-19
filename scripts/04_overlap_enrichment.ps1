<#
.SYNOPSIS
    Runs ChromHMM OverlapEnrichment against hg38 coordinate annotations.

.DESCRIPTION
    Compares learned state segments to bundled hg38 BED annotations
    (genes, exons, enhancers, etc.) under ChromHMM/ChromHMM/COORDS/hg38/.

.EXAMPLE
    .\scripts\04_overlap_enrichment.ps1
    .\scripts\04_overlap_enrichment.ps1 -NumStates 15
#>

param(
    [int]$NumStates = 15
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "C:\Users\mukun\chromhmm-project"
$Jar = Join-Path $ProjectRoot "ChromHMM\ChromHMM\ChromHMM.jar"
$ModelDir = Join-Path $ProjectRoot "models\K562_${NumStates}state"
$CoordsDir = Join-Path $ProjectRoot "ChromHMM\ChromHMM\COORDS\hg38"
$OutDir = Join-Path $ProjectRoot "results\overlap_enrichment_${NumStates}"

Write-Host "=== OverlapEnrichment (04_overlap_enrichment.ps1) ===" -ForegroundColor Cyan
Write-Host "Segmentations: $ModelDir"
Write-Host "Coordinates:   $CoordsDir"
Write-Host "Output:        $OutDir"

if (-not (Test-Path $Jar)) {
    Write-Host "ERROR: ChromHMM.jar missing. Run .\scripts\01_setup.ps1 first." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $CoordsDir)) {
    Write-Host "ERROR: hg38 COORDS not found at $CoordsDir" -ForegroundColor Red
    exit 1
}

$segments = Get-ChildItem -Path $ModelDir -Filter "*_${NumStates}_segments.bed" -ErrorAction SilentlyContinue
if (-not $segments) {
    Write-Host "ERROR: No *_${NumStates}_segments.bed in $ModelDir. Run .\scripts\03_learn_model.ps1 first." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

Write-Host "`nRunning OverlapEnrichment on $($segments.Count) segmentation file(s)..."
& java -mx4000M -jar $Jar OverlapEnrichment $ModelDir $CoordsDir $OutDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$htmlFiles = Get-ChildItem -Path $OutDir -Filter "*.html" -Recurse -ErrorAction SilentlyContinue
$txtFiles = Get-ChildItem -Path $OutDir -Filter "*.txt" -Recurse -ErrorAction SilentlyContinue

if ($htmlFiles.Count -gt 0 -or $txtFiles.Count -gt 0) {
    Write-Host "`nOK: Enrichment output in $OutDir" -ForegroundColor Green
    Write-Host "  HTML reports: $($htmlFiles.Count)"
    Write-Host "  Text tables:  $($txtFiles.Count)"
} else {
    Write-Host "`nWARNING: No HTML/TXT enrichment files found. Check ChromHMM logs." -ForegroundColor Yellow
}

Write-Host "`nNext: .\scripts\05_neighborhood_enrichment.ps1" -ForegroundColor Green
