param(
    [string]$RepoRoot = (Get-Location).Path,
    [string]$ReportRoot = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'codex_memory_steward_logs'),
    [string[]]$SessionRoots = @(
        (Join-Path $env:USERPROFILE '.codex\sessions'),
        (Join-Path $env:USERPROFILE '.codex\archived_sessions'),
        (Join-Path $env:USERPROFILE '.codex\history.jsonl')
    ),
    [int]$SessionLookbackDays = 35,
    [switch]$Apply
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

function ConvertTo-ProjectRelativePath {
    param([string]$Root, [string]$Path)
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $pathFull.Substring($rootFull.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
        return ($relative -replace '\\', '/')
    }
    return $pathFull
}

function Test-ProbablyTextFile {
    param([string]$File)
    $buffer = New-Object byte[] 4096
    $stream = [System.IO.File]::OpenRead($File)
    try {
        $read = $stream.Read($buffer, 0, $buffer.Length)
        for ($i = 0; $i -lt $read; $i++) {
            if ($buffer[$i] -eq 0) { return $false }
        }
        return $true
    }
    finally {
        $stream.Dispose()
    }
}

function Get-ProjectFiles {
    param([string]$Root)
    $skipDirs = @('.git', '.agent', '.cache', 'node_modules', 'dist', 'build', 'bin', 'obj', '__pycache__', '.venv', 'venv')
    Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $relative = ConvertTo-ProjectRelativePath -Root $Root -Path $_.FullName
            $parts = $relative -split '/'
            foreach ($part in $parts) {
                if ($skipDirs -contains $part) { return $false }
            }
            return $true
        } |
        Sort-Object FullName
}

function Get-FileSummary {
    param([System.IO.FileInfo]$File, [string]$Root)
    $relative = ConvertTo-ProjectRelativePath -Root $Root -Path $File.FullName
    if (-not (Test-ProbablyTextFile -File $File.FullName)) {
        return 'binary or non-text file'
    }
    $lines = @(Get-Content -LiteralPath $File.FullName -TotalCount 80 -ErrorAction SilentlyContinue)
    $firstUseful = @($lines | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and -not $_.StartsWith('#') -and -not $_.StartsWith('//') -and -not $_.StartsWith('<!-- usage:') } | Select-Object -First 1)
    if ($firstUseful.Count -gt 0) {
        $summary = $firstUseful[0]
    }
    elseif ($lines.Count -gt 0) {
        $summary = ($lines[0]).Trim()
    }
    else {
        $summary = 'empty text file'
    }
    if ($summary.Length -gt 120) { $summary = $summary.Substring(0, 117) + '...' }
    return $summary
}

function Update-ProjectInventory {
    param([string]$Root, [string]$InventoryFile)
    $files = @(Get-ProjectFiles -Root $Root)
    $values = New-Object System.Collections.Generic.List[string]
    $values.Add('# Project File Inventory')
    $values.Add('')
    $values.Add('<!-- usage:agent.inventory.files count=0 since=' + (Get-Date -Format 'yyyy-MM-dd') + ' last=never -->')
    $values.Add('')
    $values.Add('Generated by `scripts/run_memory_steward.ps1 -Apply`. Refresh when project layout or file roles change.')
    $values.Add('')
    $values.Add('| Path | Size | Rough content |')
    $values.Add('| --- | ---: | --- |')
    foreach ($file in $files) {
        $relative = ConvertTo-ProjectRelativePath -Root $Root -Path $file.FullName
        $summary = (Get-FileSummary -File $file -Root $Root) -replace '\|', '/'
        $values.Add(('| `{0}` | {1} | {2} |' -f $relative, $file.Length, $summary))
    }
    Set-Content -LiteralPath $InventoryFile -Value $values
}

function Update-AgentIndex {
    param([string]$Root, [string]$AgentFile)
    $today = Get-Date -Format 'yyyy-MM-dd'
    if (-not (Test-Path -LiteralPath $AgentFile)) {
        $projectName = Split-Path -Leaf (Resolve-Path -LiteralPath $Root)
        $initial = @(
            '# Project Memory',
            '',
            ('<!-- usage:agent.root.index count=0 since={0} last=never -->' -f $today),
            '',
            'Memory for this project lives here, not under `~/.codex`.',
            '',
            '## Index',
            '',
            '- `.agent/project_inventory.md`: project file tree and rough file-content map.',
            '',
            '## Stable Lessons',
            '',
            ('- Project: `{0}`.' -f $projectName),
            ''
        )
        Set-Content -LiteralPath $AgentFile -Value $initial
        return
    }

    $text = [System.IO.File]::ReadAllText($AgentFile)
    $changed = $false
    if ($text -notmatch 'usage:agent\.root\.index') {
        $text = $text.TrimEnd() + "`r`n`r`n<!-- usage:agent.root.index count=0 since=$today last=never -->`r`n"
        $changed = $true
    }
    if ($text -notmatch [regex]::Escape('.agent/project_inventory.md')) {
        $addition = @(
            '',
            '## Index',
            '',
            '- `.agent/project_inventory.md`: project file tree and rough file-content map.',
            ''
        ) -join "`r`n"
        $text = $text.TrimEnd() + "`r`n" + $addition
        $changed = $true
    }
    if ($changed) {
        Set-Content -LiteralPath $AgentFile -Value $text
    }
}

function Update-MemorySystem {
    param([string]$Root)
    if (-not (Test-Path -LiteralPath $Root)) {
        throw "RepoRoot does not exist: $Root"
    }
    $agentDir = Join-Path $Root '.agent'
    New-Item -ItemType Directory -Force -Path $agentDir | Out-Null
    $agentFile = Join-Path $Root 'agent.md'
    $inventoryFile = Join-Path $agentDir 'project_inventory.md'
    Update-AgentIndex -Root $Root -AgentFile $agentFile
    Update-ProjectInventory -Root $Root -InventoryFile $inventoryFile
    return [pscustomobject]@{
        AgentFile = $agentFile
        InventoryFile = $inventoryFile
    }
}

if ($Apply) {
    $updated = Update-MemorySystem -Root $RepoRoot
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
if ($Apply) {
    Add-Content -LiteralPath $report -Value ('- Updated agent.md: `{0}`' -f $updated.AgentFile)
    Add-Content -LiteralPath $report -Value ('- Updated inventory: `{0}`' -f $updated.InventoryFile)
}
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
