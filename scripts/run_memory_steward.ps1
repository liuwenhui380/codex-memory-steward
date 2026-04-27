param(
    [string]$RepoRoot = (Get-Location).Path,
    [string]$ReportRoot = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'codex_memory_steward_logs'),
    [string[]]$SessionRoots = @(
        (Join-Path $env:USERPROFILE '.codex\sessions'),
        (Join-Path $env:USERPROFILE '.codex\archived_sessions'),
        (Join-Path $env:USERPROFILE '.codex\history.jsonl')
    ),
    [int]$SessionLookbackDays = 35
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'

function Get-TextLineCount {
    param([string]$File)
    if (-not (Test-Path -LiteralPath $File)) { return 0 }
    $text = [System.IO.File]::ReadAllText($File)
    if ($text.Length -eq 0) { return 0 }
    $breaks = [regex]::Matches($text, "`r`n|`n|`r").Count
    if ($text.EndsWith("`n") -or $text.EndsWith("`r")) { return $breaks }
    return $breaks + 1
}

function Get-UsageMarkers {
    param([string]$Path)
    $files = @()
    foreach ($candidate in @('agent.md', 'AGENTS.md', 'README.md')) {
        $full = Join-Path $Path $candidate
        if (Test-Path -LiteralPath $full) { $files += $full }
    }
    $agentDir = Join-Path $Path '.agent'
    if (Test-Path -LiteralPath $agentDir) {
        $files += Get-ChildItem -LiteralPath $agentDir -Filter '*.md' -File -Recurse | ForEach-Object { $_.FullName }
    }
    $pattern = '<!--\s*usage:([A-Za-z0-9_.-]+)\s+count=(\d+)(?:\s+since=([^\s]+))?\s+last=([^\s]+)\s*-->'
    $markers = New-Object System.Collections.Generic.List[object]
    foreach ($file in $files) {
        $lineNo = 0
        foreach ($line in Get-Content -LiteralPath $file) {
            $lineNo++
            $match = [regex]::Match($line, $pattern)
            if ($match.Success) {
                $markers.Add([pscustomobject]@{
                    Id = $match.Groups[1].Value
                    Count = [int]$match.Groups[2].Value
                    Since = if ($match.Groups[3].Success) { $match.Groups[3].Value } else { 'unknown' }
                    Last = $match.Groups[4].Value
                    File = $file
                    Line = $lineNo
                })
            }
        }
    }
    return $markers
}

function Get-SessionFiles {
    param([string[]]$Roots, [datetime]$Cutoff)
    $files = New-Object System.Collections.Generic.List[object]
    foreach ($root in $Roots) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $item = Get-Item -LiteralPath $root
        if ($item.PSIsContainer) {
            Get-ChildItem -LiteralPath $root -Recurse -File -Include '*.jsonl','*.md','*.log','*.txt' -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -ge $Cutoff } |
                ForEach-Object { $files.Add($_) }
        }
        elseif ($item.LastWriteTime -ge $Cutoff) {
            $files.Add($item)
        }
    }
    return @($files | Sort-Object FullName -Unique)
}

New-Item -ItemType Directory -Force -Path $ReportRoot | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$report = Join-Path $ReportRoot "memory-steward-$timestamp.md"

$agentFile = Join-Path $RepoRoot 'agent.md'
$markers = @(Get-UsageMarkers -Path $RepoRoot)
$cutoff = (Get-Date).AddDays(-1 * $SessionLookbackDays)
$sessionFiles = @(Get-SessionFiles -Roots $SessionRoots -Cutoff $cutoff)

Set-Content -LiteralPath $report -Value "# Codex Memory Steward Report`n"
Add-Content -LiteralPath $report -Value ('- Repo: `{0}`' -f $RepoRoot)
Add-Content -LiteralPath $report -Value ('- agent.md lines: `{0}`' -f (Get-TextLineCount -File $agentFile))
Add-Content -LiteralPath $report -Value ('- Usage markers: `{0}`' -f $markers.Count)
Add-Content -LiteralPath $report -Value ('- Session files in lookback: `{0}`' -f $sessionFiles.Count)
Add-Content -LiteralPath $report -Value ""
Add-Content -LiteralPath $report -Value "## Usage Markers"
foreach ($marker in $markers | Sort-Object Id) {
    Add-Content -LiteralPath $report -Value ('- `{0}` count={1} since={2} last={3} in `{4}` line {5}' -f $marker.Id, $marker.Count, $marker.Since, $marker.Last, $marker.File, $marker.Line)
}
Add-Content -LiteralPath $report -Value ""
Add-Content -LiteralPath $report -Value "## Compression Priority Reference"
$markersWithCount = @($markers | Where-Object { $_.PSObject.Properties.Name -contains 'Count' })
$priorityMarkers = @($markersWithCount | Sort-Object @{ Expression = 'Count'; Descending = $true }, @{ Expression = 'Last'; Descending = $true }, Id | Select-Object -First 12)
if ($priorityMarkers.Count -eq 0) {
    Add-Content -LiteralPath $report -Value "- No usage markers found."
}
elseif (@($priorityMarkers | Where-Object { [int]$_.Count -gt 0 }).Count -eq 0) {
    Add-Content -LiteralPath $report -Value "- All usage counts are zero; preserve root/navigation entries first and compress only detailed pages after review."
}
else {
    foreach ($marker in $priorityMarkers) {
        Add-Content -LiteralPath $report -Value ('- Keep candidate: `{0}` count={1} since={2} last={3}' -f $marker.Id, $marker.Count, $marker.Since, $marker.Last)
    }
}

Write-Host "Report written: $report"
