# 基于使用频率的渐进式记忆召回实施计划

设计来源：`../specs/2026-07-12-usage-tiered-memory-recall-design.md`

## 任务 1：先建立回归测试

- 新增 `tests/run_tests.ps1`，使用临时仓库覆盖只读扫描、旧 marker 更新、重复 ID 拒绝、层级建议、大文件识别和 JSON 输出。
- 先运行测试确认新能力尚未实现，再开始修改脚本。

## 任务 2：扩展确定性扫描器

- 扩展 marker 解析，兼容可选 `tier`、`pinned` 字段。
- 增加显式 `-TouchId` 和可注入的 `-Today`，安全更新计数与日期。
- 增加调用密度、最近使用时间和固定规则驱动的层级建议。
- 增加根、索引、详情文件的行数/字节阈值检查。
- 增加完整 JSON 输出，同时保持默认 Markdown 和可选 `-ReportRoot` 行为。

## 任务 3：缩短技能入口并补充分类文档

- 将 `SKILL.md` 改为最小读取路径：扫描 → 读取匹配入口 → touch → 必要时整理。
- 更新 `references/workflow.md`，新增 `references/tiering.md`。
- 审查 Luna 子代理提供的 `references/splitting.md`，确保模型可选且不接触敏感数据。
- 更新 README 和代理默认提示词，新增记忆优先使用简体中文。

## 任务 4：验证与发布

- 运行 PowerShell 回归测试和真实 SubAPI 记忆目录只读扫描。
- 在临时副本上验证 touch，不修改真实项目计数。
- 执行 `git diff --check`、敏感信息扫描和人工差异审查。
- 保留并纳入原有 stdout/`-ReportRoot` 未提交修改。
- 提交实现，推送 `codex/usage-tiered-memory-recall` 到 GitHub。
