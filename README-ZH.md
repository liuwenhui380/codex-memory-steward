# Codex Memory Steward

[English README](README.md)

Codex Memory Steward 是一个可复用的 Codex skill 和项目记忆维护流程。它用于把长会话里的稳定经验、操作规则、文件地图和压缩前注意事项写入项目本地记忆，而不是把聊天记录原样堆进文档。

## 何时触发这个 Skill

满足以下任一高置信信号时使用：
- 任务明确提到 `agent.md`、`.agent/`、记忆层级/索引或 usage marker。
- 任务要求在上下文压缩前整理稳定记忆。
- 任务要求统一 `agent.md` 与 `.agent/index.md` 的人类可读统计展示层。
- 任务要求初始化项目本地记忆系统。

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
3. `agent.md` 以精简为目标（建议 200 行以内；超出则拆分到 `.agent/` 并说明原因）。
4. 同一记忆根的人类可读统计必须只在一个 Markdown 层展示。
5. 完成前校验层级、marker 覆盖、统计位置和密钥卫生。

## 统计展示层迁移 SOP

当 `agent.md` 与 `.agent/index.md` 同时展示人类可读统计时：
1. 检测重复展示块。
2. 选择目标层（默认 `agent.md`，除非仓库约定另有规定）。
3. 把统计表移动/合并到目标层。
4. 非目标层替换为纯导航链接。
5. 保留机器可读统计文件不变。

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
|   `-- llm_tradeoffs.md
|       `-- 脚本与 LLM 的分工说明。
|
|-- scripts/
|   `-- run_memory_steward.ps1
|       `-- PowerShell 扫描器，可选创建或更新项目记忆系统。
|
`-- RELEASE_NOTES.md
    `-- 发布说明。
```

## 边界规则

- 不要把项目记忆写入 `~/.codex`；那里只作为 session 记录的输入来源。
- 不要把密钥、凭据、token 或原始私密 transcript 写入记忆文档。
- 父级 `agent.md` 不要直接链接到子项目 `.agent/` 的私有细节，除非目标页面明确标记为多个子项目共享。
- 同一个记忆根里，人类可读的使用统计不要同时放在 `agent.md` 和 `.agent/index.md`。
