<#
.SYNOPSIS
    Runs ChromHMM NeighborhoodEnrichment around RefSeq TSS annotations.

.DESCRIPTION
    Measures enrichment of each chromatin state in windows around
    transcription start sites using hg38 RefSeq TSS coordinates from
    ChromHMM/ChromHMM/COORDS/hg38/.

.EXAMPLE
    .\scripts\05_neighborhood_enrichment.ps1
    .\scripts\05_neighborhood_enrichment.ps1 -NumStates 15
#>

param(
    [int]$NumStates = 15
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "C:\Users\mukun\chromhmm-project"
$Jar = Join-Path $ProjectRoot "ChromHMM\ChromHMM\ChromHMM.jar"
$ModelDir = Join-Path $ProjectRoot "models\K562_${NumStates}state"
$CoordsDir = Join-Path $ProjectRoot "ChromHMM\ChromHMM\COORDS\hg38"
$OutDir = Join-Path $ProjectRoot "results\neighborhood_enrichment_${NumStates}"

Write-Host "=== NeighborhoodEnrichment (05_neighborhood_enrichment.ps1) ===" -ForegroundColor Cyan
Write-Host "Segmentations: $ModelDir"
Write-Host "Annotations:   $CoordsDir (RefSeq TSS and related)"
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

Write-Host "`nRunning NeighborhoodEnrichment..."
& java -mx4000M -jar $Jar NeighborhoodEnrichment $ModelDir $CoordsDir $OutDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$htmlFiles = Get-ChildItem -Path $OutDir -Filter "*.html" -Recurse -ErrorAction SilentlyContinue
if ($htmlFiles.Count -gt 0) {
    Write-Host "`nOK: Neighborhood enrichment reports in $OutDir ($($htmlFiles.Count) HTML)" -ForegroundColor Green
} else {
    Write-Host "`nWARNING: No HTML reports found. Check ChromHMM logs." -ForegroundColor Yellow
}

Write-Host "`nNext: python .\scripts\06_interpret_states.py" -ForegroundColor Green
