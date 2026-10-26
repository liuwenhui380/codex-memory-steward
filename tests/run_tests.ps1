param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script = Join-Path $RepoRoot 'scripts\run_memory_steward.ps1'
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ('memory-steward-tests-' + [guid]::NewGuid().ToString('N'))

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
}

try {
    New-Item -ItemType Directory -Path $temp | Out-Null
    Set-Content -LiteralPath (Join-Path $temp 'agent.md') -Value '<!-- usage:agent.test count=2 since=2026-01-01 last=2026-01-02 -->' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $temp 'notes.md') -Value '# Notes`r`nSafe content' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $temp '.env') -Value 'API_KEY=do-not-index' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $temp 'settings.txt') -Value 'password=do-not-index' -Encoding utf8

    $before = @(Get-ChildItem -LiteralPath $temp -Recurse -Force | Select-Object -ExpandProperty FullName)
    $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $script -RepoRoot $temp -SessionRoots '')
    $after = @(Get-ChildItem -LiteralPath $temp -Recurse -Force | Select-Object -ExpandProperty FullName)
    Assert-True (($before -join "`n") -eq ($after -join "`n")) 'read-only mode must not create files'
    Assert-True (($output -join "`n") -match 'Usage markers: `1`') 'read-only mode should print the report'

    $reportDir = Join-Path $temp 'reports'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $script -RepoRoot $temp -SessionRoots '' -ReportRoot $reportDir | Out-Null
    $report = Get-Content -LiteralPath (Get-ChildItem -LiteralPath $reportDir -Filter '*.md' | Select-Object -First 1).FullName -Raw
    Assert-True ($report -match 'sensitive file omitted|sensitive content omitted' -or $report -notmatch 'do-not-index') 'reports must not expose secret values'

    $applyRoot = Join-Path $temp 'apply'
    New-Item -ItemType Directory -Path $applyRoot | Out-Null
    Set-Content -LiteralPath (Join-Path $applyRoot '.env') -Value 'API_KEY=do-not-index' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $applyRoot 'settings.txt') -Value 'password=do-not-index' -Encoding utf8
    & powershell -NoProfile -ExecutionPolicy Bypass -File $script -RepoRoot $applyRoot -SessionRoots '' -Apply | Out-Null
    Assert-True (Test-Path -LiteralPath (Join-Path $applyRoot 'agent.md')) 'Apply must create agent.md'
    Assert-True (Test-Path -LiteralPath (Join-Path $applyRoot '.agent\project_inventory.md')) 'Apply must create project inventory'
    $inventory = Get-Content -LiteralPath (Join-Path $applyRoot '.agent\project_inventory.md') -Raw
    Assert-True ($inventory -notmatch 'do-not-index') 'inventory must not expose secret values'
    Assert-True ($inventory -notmatch '\.env') 'inventory must omit sensitive filenames'

    $markerRoot = Join-Path $temp 'markers'
    New-Item -ItemType Directory -Path $markerRoot | Out-Null
    Set-Content -LiteralPath (Join-Path $markerRoot 'agent.md') -Value @(
        '<!-- usage:agent.duplicate count=0 since=bad-date last=never -->',
        '<!-- usage:agent.duplicate count=1 since=2026-01-01 last=bad-date -->'
    ) -Encoding utf8
    $markerOutput = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $script -RepoRoot $markerRoot -SessionRoots '') -join "`n"
    Assert-True ($markerOutput -match 'duplicate-id') 'duplicate markers must be reported'
    Assert-True ($markerOutput -match 'invalid-since') 'invalid since dates must be reported'
    Assert-True ($markerOutput -match 'invalid-last') 'invalid last dates must be reported'

    Write-Output 'All tests passed.'
}
finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
