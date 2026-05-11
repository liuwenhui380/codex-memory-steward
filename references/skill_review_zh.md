# `codex-memory-steward` Skill 评估与改进建议

## 主要问题

1. **触发条件过宽，容易被误触发**
   - `description` 中包含了“create or update ... memory docs”等宽泛场景，和一般文档整理任务存在重叠。
   - 改进方向：把触发条件压缩成 3~5 个高置信信号（例如：用户明确提到 `agent.md`、`.agent/`、context compression、usage marker）。

2. **规范较多但缺少优先级与冲突处理规则**
   - 当前规则覆盖层级、统计、索引、压缩前更新等，但没有明确“冲突时谁优先”。
   - 改进方向：增加“决策优先级”段落（用户显式要求 > 仓库既有约定 > 默认 workflow）。

3. **200 行限制表达过硬，缺少例外条件**
   - “Keep each `agent.md` under 200 lines”在复杂项目中可能不现实。
   - 改进方向：改为软限制（例如目标 <200，超过时必须拆分并解释原因）。

4. **语言与术语混用，可能影响跨团队稳定执行**
   - 文档中中英术语并行、并含“调用次数/有效调用”等多词描述，执行时可能出现不一致。
   - 改进方向：维护一份术语表（例如仅使用 `count/since/last`），并给出中文别名映射但不混写。

5. **“统计只放一层”的规则缺少迁移路径**
   - 规则要求明确，但对已有项目如何迁移、如何避免破坏历史数据描述不足。
   - 改进方向：增加迁移步骤：检测 -> 选择目标层 -> 链接替换 -> 历史段落归档。

6. **验证清单缺少“失败时如何修复”的闭环**
   - 当前 checklist 偏“判定”，缺少“若失败应做什么”。
   - 改进方向：为每个校验项附一条最小修复动作（MRA）。

7. **脚本依赖存在平台假设**
   - Resources 里主推 `run_memory_steward.ps1`，Linux/macOS 用户可用性弱。
   - 改进方向：补充 Bash/Python 等价入口，或在 skill 内明确平台分支。

8. **缺少输出契约（Output Contract）**
   - 目前说明“做什么”，但没有统一的输出格式，难以被上层流程消费。
   - 改进方向：定义固定输出块：变更摘要、受影响路径、风险、待确认事项。

## 可落地优化清单（建议优先级）

### P0（立即）
- 缩窄触发条件并增加“非触发场景”。
- 增加“规则冲突优先级”。
- 给 validation checklist 增加“失败 -> 修复动作”。

### P1（近期）
- 将 200 行限制改为软约束并给拆分模板。
- 增加统计层迁移 SOP。
- 增加输出契约模板。

### P2（中期）
- 提供跨平台脚本入口（PowerShell + Bash/Python）。
- 增加术语表和中英映射策略。

## 建议的最小模板片段

```md
## Decision Priority
1) User explicit instruction
2) Existing repo-local convention (`agent.md` / `.agent/`)
3) Default workflow in this skill

## Output Contract
- Changed files:
- Stable lessons added/updated:
- Risk & ambiguity:
- Follow-up actions:

## Validation with Repair
- Check: stats displayed in exactly one markdown layer
  - If fail: keep display in `agent.md`, replace `.agent/index.md` table with link only
```

## 总结

这个 skill 的方向和信息密度都很好，尤其是“分层记忆 + 使用频率驱动提升”的核心思想是可复用的。当前主要短板不在理念，而在**执行一致性与可操作性**：触发边界、冲突优先级、迁移闭环和输出契约还可以进一步产品化。
