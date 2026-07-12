param(
    [string]$RepoRoot = (Get-Location).Path,
    [string]$ReportRoot = '',
    [string[]]$SessionRoots = @(
        (Join-Path $env:USERPROFILE '.codex\sessions'),
        (Join-Path $env:USERPROFILE '.codex\archived_sessions'),
        (Join-Path $env:USERPROFILE '.codex\history.jsonl')
    ),
    [int]$SessionLookbackDays = 35,
    [string[]]$TouchId = @(),
    [datetime]$Today = (Get-Date).Date,
    [ValidateSet('Markdown', 'Json')]
    [string]$OutputFormat = 'Markdown',
    [switch]$Quiet,
    [int]$RootMaxLines = 80,
    [int]$IndexMaxLines = 80,
    [int]$DetailMaxLines = 120,
    [int]$DetailMaxBytes = 12288,
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

function Get-MemoryFiles {
    param([string]$Path)

    $files = @()
    foreach ($candidate in @('agent.md', 'AGENTS.md', 'README.md')) {
        $full = Join-Path $Path $candidate
        if (Test-Path -LiteralPath $full) { $files += $full }
    }
    $agentDir = Join-Path $Path '.agent'
    if (Test-Path -LiteralPath $agentDir) {
        $files += Get-ChildItem -LiteralPath $agentDir -Filter '*.md' -File -Recurse |
            ForEach-Object { $_.FullName }
    }
    return @($files | Sort-Object -Unique)
}

function Get-UsageMarkers {
    param(
        [string]$Path,
        [System.Collections.Generic.List[string]]$Diagnostics
    )

    $files = @(Get-MemoryFiles -Path $Path)
    # 代码围栏中的 marker 只是文档示例，不能计入真实调用记录。
    $pattern = '^\s*<!--\s*usage:(?<Id>[A-Za-z0-9_.-]+)\s+count=(?<Count>\d+)(?:\s+since=(?<Since>[^\s]+))?\s+last=(?<Last>[^\s]+)(?:\s+tier=(?<Tier>root|index|detail|archive))?(?:\s+pinned=(?<Pinned>true|false))?\s*-->\s*$'
    $markers = New-Object System.Collections.Generic.List[object]
    foreach ($file in $files) {
        $lineNo = 0
        $inFence = $false
        foreach ($line in [System.IO.File]::ReadAllLines($file)) {
            $lineNo++
            if ($line -match '^\s*(```|~~~)') {
                $inFence = -not $inFence
                continue
            }
            if ($inFence) { continue }
            $match = [regex]::Match($line, $pattern)
            if ($match.Success) {
                $markers.Add([pscustomobject]@{
                    Id = $match.Groups['Id'].Value
                    Count = [int]$match.Groups['Count'].Value
                    Since = if ($match.Groups['Since'].Success) { $match.Groups['Since'].Value } else { 'unknown' }
                    Last = $match.Groups['Last'].Value
                    Tier = if ($match.Groups['Tier'].Success) { $match.Groups['Tier'].Value } else { '' }
                    TierSpecified = $match.Groups['Tier'].Success
                    Pinned = $match.Groups['Pinned'].Success -and $match.Groups['Pinned'].Value -eq 'true'
                    PinnedSpecified = $match.Groups['Pinned'].Success
                    File = $file
                    Line = $lineNo
                    RawLine = $line
                })
            }
            elseif ($line -match '<!--\s*usage:') {
                $Diagnostics.Add("marker 格式无效：$file 第 $lineNo 行")
            }
        }
    }
    return $markers
}

function Add-DuplicateMarkerDiagnostics {
    param(
        [object[]]$Markers,
        [System.Collections.Generic.List[string]]$Diagnostics
    )

    foreach ($group in $Markers | Group-Object Id | Where-Object Count -gt 1) {
        $locations = @($group.Group | ForEach-Object { "$($_.File):$($_.Line)" }) -join '；'
        $Diagnostics.Add("marker ID 重复：$($group.Name)；$locations")
    }
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
    $gitAvailable = $false
    try {
        $null = & git -C $Root rev-parse --is-inside-work-tree 2>$null
        $gitAvailable = ($LASTEXITCODE -eq 0)
    }
    catch {
        $gitAvailable = $false
    }
    Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $relative = ConvertTo-ProjectRelativePath -Root $Root -Path $_.FullName
            $parts = $relative -split '/'
            foreach ($part in $parts) {
                if ($skipDirs -contains $part) { return $false }
            }
            if ($gitAvailable) {
                $null = & git -C $Root check-ignore --quiet -- $relative 2>$null
                if ($LASTEXITCODE -eq 0) { return $false }
            }
            return $true
        } |
        Sort-Object FullName
}

function Get-FileSummary {
    param([System.IO.FileInfo]$File, [string]$Root)
    $relative = ConvertTo-ProjectRelativePath -Root $Root -Path $File.FullName
    if (-not (Test-ProbablyTextFile -File $File.FullName)) {
        return '二进制或非文本文件'
    }
    $lines = @([System.IO.File]::ReadLines($File.FullName, [System.Text.Encoding]::UTF8) | Select-Object -First 80)
    $firstUseful = @($lines | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and -not $_.StartsWith('#') -and -not $_.StartsWith('//') -and -not $_.StartsWith('<!-- usage:') } | Select-Object -First 1)
    if ($firstUseful.Count -gt 0) {
        $summary = $firstUseful[0]
    }
    elseif ($lines.Count -gt 0) {
        $summary = ($lines[0]).Trim()
    }
    else {
        $summary = '空文本文件'
    }
    if ($summary.Length -gt 120) { $summary = $summary.Substring(0, 117) + '...' }
    return $summary
}

function Update-ProjectInventory {
    param([string]$Root, [string]$InventoryFile)
    $files = @(Get-ProjectFiles -Root $Root)
    $values = New-Object System.Collections.Generic.List[string]
    $values.Add('# 项目文件索引')
    $values.Add('')
    $values.Add('<!-- usage:agent.inventory.files count=0 since=' + (Get-Date -Format 'yyyy-MM-dd') + ' last=never -->')
    $values.Add('')
    $values.Add('由 `scripts/run_memory_steward.ps1 -Apply` 生成；项目结构或文件职责变化后重新运行。')
    $values.Add('')
    $values.Add('| Path | Size | 内容摘要 |')
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
            '# 项目记忆',
            '',
            ('<!-- usage:agent.root.index count=0 since={0} last=never -->' -f $today),
            '',
            '本项目记忆存放在项目内，不写入 `~/.codex`。',
            '',
            '## 索引',
            '',
            '- `.agent/project_inventory.md`：项目文件树和内容摘要。',
            '',
            '## 稳定记忆',
            '',
            ('- 项目：`{0}`。' -f $projectName),
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
            '## 索引',
            '',
            '- `.agent/project_inventory.md`：项目文件树和内容摘要。',
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

function Test-PathInsideRoot {
    param([string]$Path, [string]$Root)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    return $fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-NoReparsePointToRoot {
    param([string]$Path, [string]$Root)

    $rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $current = Get-Item -LiteralPath $Path -Force
    while ($null -ne $current) {
        if ($current.FullName.TrimEnd('\', '/') -eq $rootPath) { return $true }
        if (($current.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $false }
        $parentPath = Split-Path -Parent $current.FullName
        if ([string]::IsNullOrWhiteSpace($parentPath) -or $parentPath -eq $current.FullName) { break }
        $current = Get-Item -LiteralPath $parentPath -Force
    }
    return $false
}

function Get-InferredTier {
    param([string]$File, [string]$Root)

    $relative = [System.IO.Path]::GetRelativePath($Root, $File).Replace('\', '/')
    if ($relative -in @('agent.md', 'AGENTS.md')) { return 'root' }
    if ($relative -match '(^|/)(archive|archives)(/|$)' -or $relative -match 'archive') { return 'archive' }
    if ($relative.StartsWith('.agent/memory_parts/')) { return 'detail' }
    if ($relative.StartsWith('.agent/')) { return 'index' }
    return 'detail'
}

function ConvertTo-DateInfo {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -in @('unknown', 'never')) {
        return [pscustomobject]@{ Valid = $true; HasDate = $false; Value = $null }
    }
    $parsed = [datetime]::MinValue
    $valid = [datetime]::TryParseExact(
        $Value,
        'yyyy-MM-dd',
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::None,
        [ref]$parsed
    )
    return [pscustomobject]@{ Valid = $valid; HasDate = $valid; Value = if ($valid) { $parsed.Date } else { $null } }
}

function Get-ByteHash {
    param([byte[]]$Bytes)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $sha.Dispose()
    }
}

function Update-UsageMarkers {
    param(
        [string[]]$Ids,
        [datetime]$AsOfDate,
        [string]$Root
    )

    $uniqueIds = @($Ids | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    if ($uniqueIds.Count -eq 0) { return @() }
    if ($uniqueIds.Count -ne 1) { throw '每次 touch 只能更新一个不同的 usage marker ID' }

    # 同一仓库的 touch 共用进程锁，避免并发读取旧计数后互相覆盖。
    $rootBytes = [System.Text.Encoding]::UTF8.GetBytes($Root.ToLowerInvariant())
    $lockName = 'codex-memory-steward-' + (Get-ByteHash -Bytes $rootBytes).Substring(0, 20) + '.lock'
    $lockPath = Join-Path ([System.IO.Path]::GetTempPath()) $lockName
    $lockStream = $null
    $deadline = [datetime]::UtcNow.AddSeconds(10)
    while ($null -eq $lockStream) {
        try {
            $lockStream = [System.IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
        }
        catch [System.IO.IOException] {
            if ([datetime]::UtcNow -ge $deadline) { throw "等待记忆计数锁超时：$lockPath" }
            Start-Sleep -Milliseconds 50
        }
    }

    try {
        # 获得锁后重新扫描，确保计数和 marker 位置不是锁外的旧快照。
        $currentDiagnostics = New-Object System.Collections.Generic.List[string]
        $currentMarkers = @(Get-UsageMarkers -Path $Root -Diagnostics $currentDiagnostics)
        Add-DuplicateMarkerDiagnostics -Markers $currentMarkers -Diagnostics $currentDiagnostics
        if ($currentDiagnostics.Count -gt 0) {
            throw "记忆 marker 存在格式或唯一性错误，拒绝 touch：$($currentDiagnostics -join '；')"
        }

        $id = $uniqueIds[0]
        $matches = @($currentMarkers | Where-Object Id -eq $id)
        if ($matches.Count -eq 0) { throw "找不到 usage marker：$id" }
        if ($matches.Count -gt 1) { throw "usage marker ID 重复，拒绝写入：$id" }
        $marker = $matches[0]
        if (-not (Test-PathInsideRoot -Path $marker.File -Root $Root)) {
            throw "usage marker 位于 RepoRoot 外，拒绝写入：$($marker.File)"
        }
        if (-not (Test-NoReparsePointToRoot -Path $marker.File -Root $Root)) {
            throw "usage marker 路径包含符号链接或重解析点，拒绝写入：$($marker.File)"
        }
        $sinceInfo = ConvertTo-DateInfo -Value $marker.Since
        if (-not $sinceInfo.Valid) { throw "usage marker since 日期无效：$id" }
        $lastInfo = ConvertTo-DateInfo -Value $marker.Last
        if (-not $lastInfo.Valid) { throw "usage marker last 日期无效：$id" }

        # marker 写入只接受严格 UTF-8，并保留原 BOM 与全部换行字节。
        $originalBytes = [System.IO.File]::ReadAllBytes($marker.File)
        $hasUtf8Bom = $originalBytes.Length -ge 3 -and $originalBytes[0] -eq 0xEF -and $originalBytes[1] -eq 0xBB -and $originalBytes[2] -eq 0xBF
        $hasUtf16Or32Bom = ($originalBytes.Length -ge 2 -and (
            ($originalBytes[0] -eq 0xFF -and $originalBytes[1] -eq 0xFE) -or
            ($originalBytes[0] -eq 0xFE -and $originalBytes[1] -eq 0xFF)
        )) -or ($originalBytes.Length -ge 4 -and (
            ($originalBytes[0] -eq 0x00 -and $originalBytes[1] -eq 0x00 -and $originalBytes[2] -eq 0xFE -and $originalBytes[3] -eq 0xFF) -or
            ($originalBytes[0] -eq 0xFF -and $originalBytes[1] -eq 0xFE -and $originalBytes[2] -eq 0x00 -and $originalBytes[3] -eq 0x00)
        ))
        if ($hasUtf16Or32Bom) { throw "marker 文件不是 UTF-8，拒绝改写：$($marker.File)" }

        $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
        $offset = if ($hasUtf8Bom) { 3 } else { 0 }
        try {
            $text = $strictUtf8.GetString($originalBytes, $offset, $originalBytes.Length - $offset)
        }
        catch [System.Text.DecoderFallbackException] {
            throw "marker 文件包含无效 UTF-8 字节，拒绝改写：$($marker.File)"
        }

        $dateText = $AsOfDate.ToString('yyyy-MM-dd')
        $since = if ($marker.Since -in @('', 'unknown')) { $dateText } else { $marker.Since }
        $newLine = "<!-- usage:$($marker.Id) count=$($marker.Count + 1) since=$since last=$dateText"
        if ($marker.TierSpecified) { $newLine += " tier=$($marker.Tier)" }
        if ($marker.PinnedSpecified) { $newLine += " pinned=$($marker.Pinned.ToString().ToLowerInvariant())" }
        $newLine += ' -->'

        $linePattern = '(?m)^' + [regex]::Escape($marker.RawLine) + '(?=\r?$)'
        $lineMatches = [regex]::Matches($text, $linePattern)
        if ($lineMatches.Count -ne 1) { throw "无法唯一定位 usage marker 行，拒绝写入：$id" }
        $replacement = [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $newLine }
        $updatedText = [regex]::Replace($text, $linePattern, $replacement, 1)

        $contentBytes = $strictUtf8.GetBytes($updatedText)
        if ($hasUtf8Bom) {
            $updatedBytes = New-Object byte[] ($contentBytes.Length + 3)
            $updatedBytes[0] = 0xEF; $updatedBytes[1] = 0xBB; $updatedBytes[2] = 0xBF
            [System.Array]::Copy($contentBytes, 0, $updatedBytes, 3, $contentBytes.Length)
        }
        else {
            $updatedBytes = $contentBytes
        }

        # 先完整落到同目录临时文件，再以原子 replace 切换；目标在切换前若变化则放弃。
        $suffix = '.memory-steward-' + [guid]::NewGuid().ToString('N')
        $tempFile = $marker.File + $suffix + '.tmp'
        $backupFile = $marker.File + $suffix + '.bak'
        try {
            $tempStream = [System.IO.File]::Open($tempFile, 'CreateNew', 'Write', 'None')
            try {
                $tempStream.Write($updatedBytes, 0, $updatedBytes.Length)
                $tempStream.Flush($true)
            }
            finally {
                $tempStream.Dispose()
            }

            $latestBytes = [System.IO.File]::ReadAllBytes($marker.File)
            if ((Get-ByteHash -Bytes $latestBytes) -ne (Get-ByteHash -Bytes $originalBytes)) {
                throw "marker 文件在 touch 期间已变化，拒绝覆盖：$($marker.File)"
            }
            [System.IO.File]::Replace($tempFile, $marker.File, $backupFile, $true)
        }
        finally {
            if (Test-Path -LiteralPath $tempFile) { Remove-Item -LiteralPath $tempFile -Force }
            if (Test-Path -LiteralPath $backupFile) { Remove-Item -LiteralPath $backupFile -Force }
        }
        return $uniqueIds
    }
    finally {
        $lockStream.Dispose()
    }
}

function Get-TierRecommendations {
    param(
        [object[]]$Markers,
        [datetime]$AsOfDate,
        [string]$Root,
        [System.Collections.Generic.List[string]]$Diagnostics
    )

    $items = New-Object System.Collections.Generic.List[object]
    foreach ($marker in $Markers) {
        $currentTier = if ($marker.TierSpecified) { $marker.Tier } else { Get-InferredTier -File $marker.File -Root $Root }
        $sinceInfo = ConvertTo-DateInfo -Value $marker.Since
        $lastInfo = ConvertTo-DateInfo -Value $marker.Last
        if (-not $sinceInfo.Valid -or -not $lastInfo.Valid) {
            $Diagnostics.Add("日期无效，无法计算层级：$($marker.Id)")
            $items.Add([pscustomobject]@{
                id = $marker.Id; current_tier = $currentTier; recommended_tier = $currentTier
                count = $marker.Count; last = $marker.Last; usage_per_30_days = 0
                pinned = $marker.Pinned; reason = '日期无效，保持当前层级'
                path = [System.IO.Path]::GetRelativePath($Root, $marker.File).Replace('\', '/')
            })
            continue
        }

        $ageDays = if ($sinceInfo.HasDate) { [math]::Max(30, ($AsOfDate.Date - $sinceInfo.Value).TotalDays) } else { 30 }
        $density = [math]::Round(($marker.Count * 30.0) / $ageDays, 2)
        $recencyDays = if ($lastInfo.HasDate) { [math]::Max(0, ($AsOfDate.Date - $lastInfo.Value).TotalDays) } else { [double]::PositiveInfinity }

        # 固定安全规则优先于频率；其余内容同时考虑调用密度和最近使用时间。
        if ($marker.Pinned) {
            $recommended = 'root'
            $reason = '安全关键记忆已固定，不允许自动下沉'
        }
        elseif (-not $lastInfo.HasDate -or ($recencyDays -gt 180 -and $marker.Count -le 1)) {
            $recommended = 'archive'
            $reason = '从未使用，或超过 180 天未使用且调用次数不高'
        }
        elseif ($recencyDays -le 30 -and $density -ge 3) {
            $recommended = 'root'
            $reason = '最近 30 天持续高频使用'
        }
        elseif ($recencyDays -le 90 -and $density -ge 1) {
            $recommended = 'index'
            $reason = '最近 90 天使用且调用密度达到索引阈值'
        }
        else {
            $recommended = 'detail'
            $reason = '仍有价值，但不需要进入常规入口'
        }

        $items.Add([pscustomobject]@{
            id = $marker.Id
            current_tier = $currentTier
            recommended_tier = $recommended
            count = $marker.Count
            last = $marker.Last
            usage_per_30_days = $density
            pinned = $marker.Pinned
            reason = $reason
            path = [System.IO.Path]::GetRelativePath($Root, $marker.File).Replace('\', '/')
        })
    }
    return $items.ToArray()
}

function Get-OversizedMemoryFiles {
    param(
        [string]$Root,
        [int]$RootLimit,
        [int]$IndexLimit,
        [int]$DetailLimit,
        [int]$ByteLimit
    )

    $memoryFiles = @()
    $rootAgent = Join-Path $Root 'agent.md'
    if (Test-Path -LiteralPath $rootAgent) { $memoryFiles += $rootAgent }
    $agentDir = Join-Path $Root '.agent'
    if (Test-Path -LiteralPath $agentDir) {
        $memoryFiles += Get-ChildItem -LiteralPath $agentDir -Filter '*.md' -File -Recurse |
            ForEach-Object { $_.FullName }
    }

    $oversized = New-Object System.Collections.Generic.List[object]
    foreach ($file in $memoryFiles | Sort-Object -Unique) {
        # root/index 使用更紧的路由阈值，detail/archive 使用具体主题阈值。
        $tier = Get-InferredTier -File $file -Root $Root
        $lineLimit = if ($tier -eq 'root') { $RootLimit } elseif ($tier -eq 'index') { $IndexLimit } else { $DetailLimit }
        $lineCount = Get-TextLineCount -File $file
        $byteCount = [System.Text.Encoding]::UTF8.GetByteCount([System.IO.File]::ReadAllText($file))
        if ($lineCount -le $lineLimit -and $byteCount -le $ByteLimit) { continue }

        $headings = @([System.IO.File]::ReadAllLines($file) |
            Where-Object { $_ -match '^#{2,3}\s+\S' } |
            Select-Object -First 8 |
            ForEach-Object { ($_ -replace '^#{2,3}\s+', '').Trim() })
        $reasons = @()
        if ($lineCount -gt $lineLimit) { $reasons += "行数 $lineCount 超过 $lineLimit" }
        if ($byteCount -gt $ByteLimit) { $reasons += "字节数 $byteCount 超过 $ByteLimit" }
        $oversized.Add([pscustomobject]@{
            path = [System.IO.Path]::GetRelativePath($Root, $file).Replace('\', '/')
            tier = $tier
            lines = $lineCount
            bytes = $byteCount
            line_limit = $lineLimit
            byte_limit = $ByteLimit
            headings = $headings
            reason = ($reasons -join '；')
        })
    }
    return $oversized.ToArray()
}

function New-MarkdownReport {
    param(
        [string]$Root,
        [int]$AgentLines,
        [object[]]$Markers,
        [object[]]$Recommendations,
        [object[]]$Oversized,
        [int]$SessionCount,
        [string[]]$Touched,
        [string[]]$Diagnostics,
        [object]$Applied
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Codex Memory Steward Report')
    $lines.Add('')
    $lines.Add(('- 项目：`{0}`' -f $Root))
    if ($null -ne $Applied) {
        $lines.Add(('- 已更新项目记忆：`{0}`' -f $Applied.AgentFile))
        $lines.Add(('- 已更新文件索引：`{0}`' -f $Applied.InventoryFile))
    }
    $lines.Add(('- agent.md 行数：`{0}`' -f $AgentLines))
    $lines.Add(('- Usage markers：`{0}`' -f $Markers.Count))
    $lines.Add(('- 最近会话文件：`{0}`' -f $SessionCount))
    if ($Touched.Count -gt 0) { $lines.Add(('- 本次已记录调用：`{0}`' -f ($Touched -join '`, `'))) }

    $lines.Add('')
    $lines.Add('## 最小召回入口')
    $topMarkers = @($Markers | Sort-Object @{ Expression = 'Pinned'; Descending = $true }, @{ Expression = 'Count'; Descending = $true }, @{ Expression = 'Last'; Descending = $true }, Id | Select-Object -First 12)
    if ($topMarkers.Count -eq 0) {
        $lines.Add('- 未找到 usage marker。')
    }
    else {
        foreach ($marker in $topMarkers) {
            $pin = if ($marker.Pinned) { ' pinned' } else { '' }
            $lines.Add(('- `{0}` count={1} last={2}{3}' -f $marker.Id, $marker.Count, $marker.Last, $pin))
        }
        if ($Markers.Count -gt $topMarkers.Count) {
            $lines.Add(('- 其余 `{0}` 个入口请使用 `-OutputFormat Json` 按需查询。' -f ($Markers.Count - $topMarkers.Count)))
        }
    }

    $changes = @($Recommendations | Where-Object { $_.current_tier -ne $_.recommended_tier })
    $lines.Add('')
    $lines.Add('## 层级转换建议')
    if ($changes.Count -eq 0) {
        $lines.Add('- 当前无需转换。')
    }
    else {
        foreach ($item in $changes | Select-Object -First 20) {
            $lines.Add(('- `{0}`：{1} -> {2}；{3}' -f $item.id, $item.current_tier, $item.recommended_tier, $item.reason))
        }
    }

    $lines.Add('')
    $lines.Add('## 大文件拆分候选')
    if ($Oversized.Count -eq 0) {
        $lines.Add('- 未发现超过层级阈值的记忆文件。')
    }
    else {
        foreach ($item in $Oversized | Select-Object -First 20) {
            $lines.Add(('- `{0}`：{1}；按具体主题拆分。' -f $item.path, $item.reason))
        }
    }

    if ($Diagnostics.Count -gt 0) {
        $lines.Add('')
        $lines.Add('## 诊断')
        foreach ($diagnostic in $Diagnostics) { $lines.Add("- $diagnostic") }
    }
    return ($lines -join "`n")
}

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) {
    throw "RepoRoot 不存在或不是目录：$RepoRoot"
}
# 使用文件系统返回的目录名，并仅为非卷根目录移除尾分隔符，确保共用同一把锁。
$RepoRoot = (Get-Item -LiteralPath $RepoRoot -Force).FullName
$volumeRoot = [System.IO.Path]::GetPathRoot($RepoRoot)
if ($RepoRoot.Length -gt $volumeRoot.Length) {
    $RepoRoot = $RepoRoot.TrimEnd('\', '/')
}

$updated = $null
if ($Apply) {
    $updated = Update-MemorySystem -Root $RepoRoot
}

$diagnostics = New-Object System.Collections.Generic.List[string]
$markers = @(Get-UsageMarkers -Path $RepoRoot -Diagnostics $diagnostics)
Add-DuplicateMarkerDiagnostics -Markers $markers -Diagnostics $diagnostics
if ($TouchId.Count -gt 0 -and $diagnostics.Count -gt 0) {
    throw "记忆 marker 存在格式或唯一性错误，拒绝 touch：$($diagnostics -join '；')"
}
$touchedIds = @(Update-UsageMarkers -Ids $TouchId -AsOfDate $Today -Root $RepoRoot)
if ($Quiet -and $touchedIds.Count -gt 0) {
    return
}
if ($touchedIds.Count -gt 0) {
    $diagnostics.Clear()
    $markers = @(Get-UsageMarkers -Path $RepoRoot -Diagnostics $diagnostics)
    Add-DuplicateMarkerDiagnostics -Markers $markers -Diagnostics $diagnostics
}

$agentFile = Join-Path $RepoRoot 'agent.md'
$cutoff = (Get-Date).AddDays(-1 * $SessionLookbackDays)
$sessionFiles = @(Get-SessionFiles -Roots $SessionRoots -Cutoff $cutoff)
$recommendations = @(Get-TierRecommendations -Markers $markers -AsOfDate $Today -Root $RepoRoot -Diagnostics $diagnostics)
$oversizedFiles = @(Get-OversizedMemoryFiles -Root $RepoRoot -RootLimit $RootMaxLines -IndexLimit $IndexMaxLines -DetailLimit $DetailMaxLines -ByteLimit $DetailMaxBytes)
$agentLines = Get-TextLineCount -File $agentFile

$reportText = New-MarkdownReport -Root $RepoRoot -AgentLines $agentLines -Markers $markers -Recommendations $recommendations -Oversized $oversizedFiles -SessionCount $sessionFiles.Count -Touched $touchedIds -Diagnostics @($diagnostics) -Applied $updated
$reportObject = [ordered]@{
    repo = $RepoRoot
    generated_on = $Today.ToString('yyyy-MM-dd')
    agent_md_lines = $agentLines
    usage_marker_count = $markers.Count
    session_file_count = $sessionFiles.Count
    applied = if ($null -eq $updated) { $null } else { [ordered]@{ agent_file = $updated.AgentFile; inventory_file = $updated.InventoryFile } }
    touched_ids = @($touchedIds)
    usage_markers = @($markers | Sort-Object Id | ForEach-Object {
        [ordered]@{
            id = $_.Id
            count = $_.Count
            since = $_.Since
            last = $_.Last
            tier = if ($_.TierSpecified) { $_.Tier } else { Get-InferredTier -File $_.File -Root $RepoRoot }
            pinned = $_.Pinned
            path = [System.IO.Path]::GetRelativePath($RepoRoot, $_.File).Replace('\', '/')
            line = $_.Line
        }
    })
    tier_recommendations = @($recommendations)
    oversized_files = @($oversizedFiles)
    diagnostics = @($diagnostics)
}

if (-not $Quiet) {
    if ($OutputFormat -eq 'Json') {
        Write-Output ($reportObject | ConvertTo-Json -Depth 8)
    }
    else {
        Write-Output $reportText
    }
}

if (-not [string]::IsNullOrWhiteSpace($ReportRoot)) {
    New-Item -ItemType Directory -Force -Path $ReportRoot | Out-Null
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $report = Join-Path $ReportRoot "memory-steward-$timestamp.md"
    Set-Content -LiteralPath $report -Value $reportText
    Write-Host "Report written: $report"
}
