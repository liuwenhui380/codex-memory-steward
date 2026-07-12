Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot 'scripts\run_memory_steward.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-memory-steward-tests-' + [guid]::NewGuid().ToString('N'))
$script:passed = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "断言失败：$Message" }
    $script:passed++
}

function Write-Utf8File {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

try {
    $fixture = Join-Path $tempRoot 'fixture'
    [System.IO.Directory]::CreateDirectory($fixture) | Out-Null

    Write-Utf8File -Path (Join-Path $fixture 'agent.md') -Content @'
<!-- usage:agent.core.safe count=8 since=2026-06-12 last=2026-07-11 tier=root pinned=true -->
# 项目记忆

- 安全规则。
'@
    Write-Utf8File -Path (Join-Path $fixture '.agent\deploy.md') -Content @'
<!-- usage:agent.deploy count=2 since=2026-06-12 last=2026-07-10 tier=index pinned=false -->
# 部署索引
'@
    Write-Utf8File -Path (Join-Path $fixture '.agent\memory_parts\legacy.md') -Content @'
<!-- usage:agent.legacy count=0 last=never -->
# 旧格式记忆
'@
    Write-Utf8File -Path (Join-Path $fixture '.agent\memory_parts\root-boundary.md') -Content @'
<!-- usage:agent.root-boundary count=3 since=2026-06-12 last=2026-06-12 tier=detail pinned=false -->
# Root 边界
'@
    Write-Utf8File -Path (Join-Path $fixture '.agent\memory_parts\index-boundary.md') -Content @'
<!-- usage:agent.index-boundary count=1 since=2026-06-12 last=2026-04-13 tier=detail pinned=false -->
# Index 边界
'@
    Write-Utf8File -Path (Join-Path $fixture '.agent\memory_parts\archive-boundary.md') -Content @'
<!-- usage:agent.archive-boundary count=1 since=2026-01-01 last=2026-01-12 tier=detail pinned=false -->
# Archive 边界
'@
    $largeLines = @('# 大文件') + (1..121 | ForEach-Object { "- 主题记录 $_" })
    Write-Utf8File -Path (Join-Path $fixture '.agent\memory_parts\large.md') -Content ($largeLines -join "`n")
    Write-Utf8File -Path (Join-Path $fixture '.agent\memory_parts\large-bytes.md') -Content ('# 字节超限' + "`n" + ('中' * 5000))
    Write-Utf8File -Path (Join-Path $fixture '.agent\memory_parts\exact-lines.md') -Content ((1..120 | ForEach-Object { "line $_" }) -join "`n")
    $exactPrefix = "# exact bytes`n"
    Write-Utf8File -Path (Join-Path $fixture '.agent\memory_parts\exact-bytes.md') -Content ($exactPrefix + ('a' * (12288 - $exactPrefix.Length)))

    $beforeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $fixture 'agent.md')).Hash
    $markdown = (& $scriptPath -RepoRoot $fixture -SessionRoots @() -Today ([datetime]'2026-07-12') | Out-String)
    $afterHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $fixture 'agent.md')).Hash
    Assert-True ($markdown -match 'Codex Memory Steward Report') '默认模式应输出 Markdown 报告'
    Assert-True ($beforeHash -eq $afterHash) '不带 TouchId 的扫描必须保持文件不变'

    & $scriptPath -RepoRoot $fixture -SessionRoots @() -TouchId 'agent.legacy' -Today ([datetime]'2026-07-12') | Out-Null
    $legacyText = [System.IO.File]::ReadAllText((Join-Path $fixture '.agent\memory_parts\legacy.md'))
    Assert-True ($legacyText -match 'count=1 since=2026-07-12 last=2026-07-12') '旧 marker 首次触达应补齐 since 并增加计数'

    $quietOutput = @(& $scriptPath -RepoRoot $fixture -SessionRoots @() -TouchId @('agent.legacy', 'agent.legacy') -Today ([datetime]'2026-07-12') -Quiet)
    $legacyText = [System.IO.File]::ReadAllText((Join-Path $fixture '.agent\memory_parts\legacy.md'))
    Assert-True ($legacyText -match 'count=2 since=2026-07-12 last=2026-07-12') '同一次调用中的重复 TouchId 只能增加一次'
    Assert-True ($quietOutput.Count -eq 0) 'Quiet touch 不应把完整报告重新送入上下文'
    Assert-True ($legacyText.Contains("`n# 旧格式记忆") -and -not $legacyText.Contains("`r`n")) '无 BOM UTF-8 文件的 LF 换行必须保持'

    $jsonText = (& $scriptPath -RepoRoot $fixture -SessionRoots @() -Today ([datetime]'2026-07-12') -OutputFormat Json | Out-String)
    $report = $jsonText | ConvertFrom-Json
    Assert-True ($report.usage_markers.Count -eq 6) 'JSON 应包含完整 marker 清单'
    $safeRecommendation = @($report.tier_recommendations | Where-Object id -eq 'agent.core.safe')[0]
    Assert-True ($safeRecommendation.recommended_tier -eq 'root') 'pinned 记忆必须保持 root'
    $legacyRecommendation = @($report.tier_recommendations | Where-Object id -eq 'agent.legacy')[0]
    Assert-True ($legacyRecommendation.recommended_tier -eq 'index') '近期使用的旧记忆应建议提升到 index'
    Assert-True ((@($report.tier_recommendations | Where-Object id -eq 'agent.root-boundary')[0]).recommended_tier -eq 'root') '30 天且密度为 3 的边界应建议 root'
    Assert-True ((@($report.tier_recommendations | Where-Object id -eq 'agent.index-boundary')[0]).recommended_tier -eq 'index') '90 天且密度为 1 的边界应建议 index'
    Assert-True ((@($report.tier_recommendations | Where-Object id -eq 'agent.archive-boundary')[0]).recommended_tier -eq 'archive') '超过 180 天且低频应建议 archive'
    Assert-True (@($report.oversized_files | Where-Object path -like '*large.md').Count -eq 1) '超过 120 行的详情文件应标记为拆分候选'
    Assert-True (@($report.oversized_files | Where-Object path -like '*large-bytes.md').Count -eq 1) '超过 12 KiB UTF-8 字节的详情文件应标记为拆分候选'
    Assert-True (@($report.oversized_files | Where-Object path -like '*exact-lines.md').Count -eq 0) '恰好 120 行不应误报'
    Assert-True (@($report.oversized_files | Where-Object path -like '*exact-bytes.md').Count -eq 0) '恰好 12 KiB UTF-8 字节不应误报'

    $legacyHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $fixture '.agent\memory_parts\legacy.md')).Hash
    $missingRejected = $false
    try {
        & $scriptPath -RepoRoot $fixture -SessionRoots @() -TouchId 'agent.missing' -Today ([datetime]'2026-07-12') | Out-Null
    }
    catch {
        $missingRejected = $true
    }
    Assert-True $missingRejected '不存在的 TouchId 必须拒绝写入'
    Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $fixture '.agent\memory_parts\legacy.md')).Hash -eq $legacyHash) 'TouchId 缺失时现有 marker 文件不能变化'

    $deployPath = Join-Path $fixture '.agent\deploy.md'
    $deployHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $deployPath).Hash
    $multiRejected = $false
    try {
        & $scriptPath -RepoRoot $fixture -TouchId @('agent.legacy', 'agent.deploy') -Today ([datetime]'2026-07-12') -Quiet
    }
    catch {
        $multiRejected = $true
    }
    Assert-True $multiRejected '一次 touch 多个不同 ID 必须拒绝，避免跨文件部分写入'
    Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $deployPath).Hash -eq $deployHash) '多 ID 被拒绝后文件不能变化'

    $bomPath = Join-Path $fixture '.agent\memory_parts\bom.md'
    $bomText = "<!-- usage:agent.bom count=0 last=never -->`r`n# BOM`r`n"
    $bomPayload = [System.Text.Encoding]::UTF8.GetBytes($bomText)
    $bomBytes = New-Object byte[] ($bomPayload.Length + 3)
    $bomBytes[0] = 0xEF; $bomBytes[1] = 0xBB; $bomBytes[2] = 0xBF
    [System.Array]::Copy($bomPayload, 0, $bomBytes, 3, $bomPayload.Length)
    [System.IO.File]::WriteAllBytes($bomPath, $bomBytes)
    & $scriptPath -RepoRoot $fixture -TouchId 'agent.bom' -Today ([datetime]'2026-07-12') -Quiet
    $bomAfter = [System.IO.File]::ReadAllBytes($bomPath)
    Assert-True ($bomAfter[0] -eq 0xEF -and $bomAfter[1] -eq 0xBB -and $bomAfter[2] -eq 0xBF) 'UTF-8 BOM 必须保留'
    $bomAfterText = [System.Text.Encoding]::UTF8.GetString($bomAfter, 3, $bomAfter.Length - 3)
    Assert-True ($bomAfterText -match 'count=1 since=2026-07-12 last=2026-07-12') 'BOM 文件 marker 应正确更新'
    Assert-True ($bomAfterText.Contains("`r`n# BOM`r`n")) 'CRLF 和结尾换行必须保持'
    Remove-Item -LiteralPath $bomPath -Force

    $invalidUtf8Path = Join-Path $fixture '.agent\memory_parts\invalid-utf8.md'
    $asciiPrefix = [System.Text.Encoding]::ASCII.GetBytes("<!-- usage:agent.invalid-utf8 count=0 last=never -->`r`n")
    $invalidBytes = New-Object byte[] ($asciiPrefix.Length + 2)
    [System.Array]::Copy($asciiPrefix, $invalidBytes, $asciiPrefix.Length)
    $invalidBytes[$asciiPrefix.Length] = 0x81; $invalidBytes[$asciiPrefix.Length + 1] = 0x40
    [System.IO.File]::WriteAllBytes($invalidUtf8Path, $invalidBytes)
    $invalidHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $invalidUtf8Path).Hash
    $invalidRejected = $false
    try {
        & $scriptPath -RepoRoot $fixture -TouchId 'agent.invalid-utf8' -Today ([datetime]'2026-07-12') -Quiet
    }
    catch {
        $invalidRejected = $true
    }
    Assert-True $invalidRejected '无效 UTF-8 文件必须拒绝改写'
    Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $invalidUtf8Path).Hash -eq $invalidHash) '编码拒绝后文件哈希必须不变'
    Remove-Item -LiteralPath $invalidUtf8Path -Force

    $pwsh = (Get-Command pwsh -ErrorAction Stop).Source
    $processArgs = @('-NoProfile', '-File', $scriptPath, '-RepoRoot', $fixture, '-TouchId', 'agent.legacy', '-Today', '2026-07-12', '-Quiet')
    $processArgsTrailing = @('-NoProfile', '-File', $scriptPath, '-RepoRoot', ($fixture + [System.IO.Path]::DirectorySeparatorChar), '-TouchId', 'agent.legacy', '-Today', '2026-07-12', '-Quiet')
    $p1 = Start-Process -FilePath $pwsh -ArgumentList $processArgs -PassThru -WindowStyle Hidden
    $p2 = Start-Process -FilePath $pwsh -ArgumentList $processArgsTrailing -PassThru -WindowStyle Hidden
    $p1.WaitForExit(); $p2.WaitForExit()
    Assert-True ($p1.ExitCode -eq 0 -and $p2.ExitCode -eq 0) '两个并发 touch 进程都应成功'
    $legacyText = [System.IO.File]::ReadAllText((Join-Path $fixture '.agent\memory_parts\legacy.md'))
    Assert-True ($legacyText -match 'count=4 since=2026-07-12 last=2026-07-12') '并发 touch 不得丢失计数'

    $duplicateFile = Join-Path $fixture '.agent\duplicate.md'
    Write-Utf8File -Path $duplicateFile -Content @'
<!-- usage:agent.deploy count=1 since=2026-07-01 last=2026-07-01 -->
# 重复 ID
'@
    $deployHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $deployPath).Hash
    $duplicateHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $duplicateFile).Hash
    $duplicateRejected = $false
    try {
        & $scriptPath -RepoRoot $fixture -SessionRoots @() -TouchId 'agent.deploy' -Today ([datetime]'2026-07-12') | Out-Null
    }
    catch {
        $duplicateRejected = $true
    }
    Assert-True $duplicateRejected '重复 marker ID 必须拒绝写入'
    Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $deployPath).Hash -eq $deployHash) '重复 ID 失败后原 marker 文件不能变化'
    Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $duplicateFile).Hash -eq $duplicateHash) '重复 ID 失败后重复文件不能变化'

    Remove-Item -LiteralPath $duplicateFile -Force
    $reportRoot = Join-Path $tempRoot 'reports'
    $jsonWithReport = (& $scriptPath -RepoRoot $fixture -SessionRoots @() -Today ([datetime]'2026-07-12') -OutputFormat Json -ReportRoot $reportRoot | Out-String | ConvertFrom-Json)
    Assert-True ($jsonWithReport.usage_marker_count -eq 6) 'Json + ReportRoot 的 stdout 必须保持可解析 JSON'
    Assert-True (@(Get-ChildItem -LiteralPath $reportRoot -Filter 'memory-steward-*.md').Count -eq 1) '显式 ReportRoot 应写入一个 Markdown 报告'
    $savedReport = Get-Content -LiteralPath @(Get-ChildItem -LiteralPath $reportRoot -Filter 'memory-steward-*.md')[0].FullName -Raw
    Assert-True ($savedReport -match '# Codex Memory Steward Report') 'ReportRoot 文件必须保持 Markdown 报告内容'

    $applyFixture = Join-Path $tempRoot 'apply-fixture'
    Write-Utf8File -Path (Join-Path $applyFixture 'src\sample.txt') -Content 'sample content'
    $applyJson = (& $scriptPath -RepoRoot $applyFixture -SessionRoots @() -Today ([datetime]'2026-07-12') -Apply -OutputFormat Json | Out-String | ConvertFrom-Json)
    $applyAgent = Join-Path $applyFixture 'agent.md'
    $applyInventory = Join-Path $applyFixture '.agent\project_inventory.md'
    Assert-True (Test-Path -LiteralPath $applyAgent) 'Apply 应在项目根创建 agent.md'
    Assert-True (Test-Path -LiteralPath $applyInventory) 'Apply 应创建项目文件索引'
    Assert-True ($null -ne $applyJson.applied) 'Apply 的 JSON 报告应返回更新路径'
    $inventoryText = [System.IO.File]::ReadAllText($applyInventory)
    Assert-True ($inventoryText -match '# 项目文件索引' -and $inventoryText -match 'src/sample.txt') '项目索引应使用中文并包含项目文件'
    Assert-True ($inventoryText -notmatch '\.agent/project_inventory\.md') '项目索引不能递归收录 .agent 输出'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $applyFixture '.agent\reports'))) '未显式提供 ReportRoot 时不得落盘报告'

    Write-Output "PASS: $script:passed assertions"
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
