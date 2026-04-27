# Codex Memory Steward

Codex Memory Steward 是一个面向长期 Codex 项目的记忆管理方法与技能包，用来把会话中真正稳定、可复用的经验整理成结构化项目记忆。

它关注的问题不是简单保存聊天记录，而是在多轮开发、长上下文压缩和跨会话协作中，保留那些会影响未来决策的项目知识。

## 大致原理

该方法把项目记忆维护拆成两个互补环节：

1. 确定性扫描

   脚本先收集可验证事实，例如 `agent.md` 行数、`.agent/` 详情页、`AGENTS.md`、`README.md`、usage marker 和近期会话记录位置。这一步负责提供稳定输入，避免模型凭印象维护记忆。

2. 语义判断与压缩

   LLM 再根据扫描结果判断哪些内容属于长期经验，哪些只是一次性调试噪声。稳定经验会被压缩成短句，放入根记忆或详细记忆页中。

3. 渐进式披露

   根目录的 `agent.md` 保持短小，只保存导航级提醒；细节放入 `.agent/*.md`。这样未来代理可以先读到核心约束，再按需展开细节。

4. 使用痕迹反馈

   usage marker 用 `count`、`since`、`last` 记录某条记忆的使用情况。高频或近期使用的记忆优先保留，低频内容则可以在人工复核后压缩或下沉。

## 创新点

- 脚本与 LLM 分工：脚本负责事实收集，LLM 负责语义筛选和表达压缩。
- 面向上下文压缩：在长会话压缩前主动固化稳定经验，减少信息断层。
- 低噪声记忆：强调保存会改变未来行为的规则，而不是保存完整会话历史。
- 分层记忆结构：用短根文件加隐藏详情页的方式，兼顾可读性和信息容量。
- usage marker 机制：把记忆的使用频率和最近使用时间纳入压缩依据。
- 可迁移技能包：核心方法不绑定某个具体项目，可复制到不同 Codex 仓库中使用。

## 方法目录结构

```text
.
|-- SKILL.md
|   `-- Codex 技能入口，定义何时使用该记忆管理方法以及核心操作流程。
|
|-- agents/
|   `-- openai.yaml
|       `-- 技能展示元数据，包括显示名称、简短说明和默认调用提示。
|
|-- references/
|   |-- workflow.md
|   |   `-- 渐进式记忆维护流程，说明根记忆、详情页和压缩检查点的职责。
|   |
|   `-- llm_tradeoffs.md
|       `-- LLM 与脚本的分工原则，列出适合模型判断和不适合模型承担的任务。
|
`-- scripts/
    `-- run_memory_steward.ps1
        `-- PowerShell 扫描脚本，用于生成项目记忆状态报告和 usage marker 摘要。
```

## 方法流程

```text
Scan project memory
        |
        v
Collect verifiable facts
        |
        v
Classify stable lessons vs. noise
        |
        v
Update root and detailed memory docs
        |
        v
Validate markers and memory size
        |
        v
Use results before future compression
```
