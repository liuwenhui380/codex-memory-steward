# Codex Memory Steward

[English README](README.md)

Codex Memory Steward 是一个可复用的 Codex skill 和项目记忆维护流程。它用于把长会话里的稳定经验、操作规则、文件地图和压缩前注意事项写入项目本地记忆，而不是把聊天记录原样堆进文档。

## 何时触发这个 Skill

满足以下任一高置信信号时使用：
- 任务明确提到 `agent.md`、`.agent/`、记忆层级/索引或 usage marker。
- 任务要求在上下文压缩前整理稳定记忆。
- 任务要求统一 `agent.md` 与 `.agent/index.md` 的人类可读统计展示层。
- 任务要求初始化项目本地记忆系统。
- 任务要求按调用频率提升/下沉记忆，或按具体主题拆分过大的记忆文件。

## 何时不应触发

如果只是通用文档润色、README 修改或与记忆治理无关的仓库清理，不应触发该 skill。

## 决策优先级

指令冲突时按以下顺序执行：
1. 用户显式要求。
2. 该记忆根的仓库既有约定。
3. `SKILL.md` 默认策略。

## 管理内容

- `agent.md`：当前目录的本地记忆入口。
- `.agent/*.md`：本地规则、事故、清单、压缩记录等详细页面。
- `.agent/project_inventory.md`：由脚本生成的项目文件清单和粗略内容地图。
- 使用标记：用 `count`、`since`、`last` 记录条目的使用频率和新旧程度。
- 会话沉淀：从 Codex session 记录中提炼稳定经验，不保存原始私密 transcript。

## 工作流要点

1. 先确认项目根目录（默认 cwd，除非用户指定其他路径）。
2. 先做确定性扫描，再让 LLM 做语义分拣。
3. `agent.md` 和分类索引目标不超过 80 行；具体主题文件不超过 120 行和 12 KiB。
4. 同一记忆根的人类可读统计必须只在一个 Markdown 层展示。
5. 只有记忆实际参与当前决策后才增加调用次数，并根据频率、最近使用时间和固定安全属性建议层级。
6. 即使内容属于同一大类，也要按可独立召回的具体主题继续拆分。
7. 完成前校验层级、marker、链接、编码、统计位置和密钥卫生。

## 统计展示层迁移 SOP

当 `agent.md` 与 `.agent/index.md` 同时展示人类可读统计时：
1. 检测重复展示块。
2. 选择目标层（默认 `agent.md`，除非仓库约定另有规定）。
3. 把统计表移动/合并到目标层。
4. 非目标层替换为纯导航链接。
5. 保留机器可读统计文件不变。

## 基于调用频率的最小召回

- `-TouchId` 只更新一个全局唯一入口，不分析完整聊天记录。
- `-Quiet` 记录调用但不把完整报告重新送入上下文。
- 默认 Markdown 报告保持紧凑；JSON 输出保留完整清单供精确筛选。
- touch 使用仓库级文件锁、严格 UTF-8 校验和原子替换，并发调用不会丢失计数。
- Luna 可从本地过滤后的内容生成语义拆分计划，但不直接写文件；最终结果由确定性脚本验证。

## 输出契约

每次执行应返回：
- 变更文件
- 新增/更新的稳定经验
- 风险与不确定点
- 后续行动

## 仓库结构

```text
.
|-- SKILL.md
|   `-- Codex skill 入口与规则边界。
|
|-- agents/
|   `-- openai.yaml
|       `-- 展示元数据、默认提示词与版本号。
|
|-- references/
|   |-- workflow.md
|   |   `-- 层级索引、统计放置和验证规则。
|   |
|   |-- tiering.md
|   |   `-- 调用计数、安全固定和 root/index/detail/archive 层级规则。
|   |
|   |-- splitting.md
|   |   `-- 具体主题拆分、Luna 计划和拆分后验证规则。
|   |
|   `-- llm_tradeoffs.md
|       `-- 脚本与 LLM 的分工说明。
|
|-- scripts/
|   `-- run_memory_steward.ps1
|       `-- PowerShell 扫描器，可创建索引、记录调用、推荐层级和识别大文件。
|
|-- tests/
|   `-- run_tests.ps1
|       `-- 覆盖并发、编码、层级、清单和大小边界的无依赖回归测试。
|
`-- CHANGELOG.md
    `-- 累积版本历史。
```

## 快速开始

```powershell
# 初始化或更新项目本地记忆与文件索引
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project -Apply

# 紧凑的只读报告
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project

# 记录一个实际使用的记忆入口，不重新输出报告
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project -TouchId agent.area.topic -Quiet

# 输出完整 JSON 清单
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project -OutputFormat Json

# 运行回归测试
./tests/run_tests.ps1
```

## 边界规则

- 不要把项目记忆写入 `~/.codex`；那里只作为 session 记录的输入来源。
- 不要把密钥、凭据、token 或原始私密 transcript 写入记忆文档。
- 父级 `agent.md` 不要直接链接到子项目 `.agent/` 的私有细节，除非目标页面明确标记为多个子项目共享。
- 同一个记忆根里，人类可读的使用统计不要同时放在 `agent.md` 和 `.agent/index.md`。
