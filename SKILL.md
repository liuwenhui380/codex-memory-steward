---
name: codex-memory-steward
description: Steward progressive Codex project memory systems with explicit usage counting, minimal recall routes, tier recommendations, and concrete-topic file splitting. Use when Codex needs to create, update, compact, promote, demote, archive, validate, or split agent.md/.agent memory; record stable lessons before context compression; or maintain reusable project memory without loading whole categories.
---

# Codex Memory Steward

Steward long-running project memory with the smallest useful recall path. Scripts collect facts and update explicit counters; the LLM decides meaning, wording, and semantic file boundaries.

## Minimal Recall Workflow

1. Run the deterministic scanner. Use Markdown for a short human report or JSON for exact filtering.
2. Read `agent.md`, then at most one matching index and one matching detail file. Do not preload an entire memory category.
3. After a stable entry actually changes the current decision or action, record that use with `-TouchId ... -Quiet`. The user does not need to update counters manually, and the report is not reloaded.
4. Write only stable lessons. Follow the user's/project's language; for Chinese projects, prefer concise Simplified Chinese while preserving technical identifiers.
5. Review tier and oversized-file recommendations. Scripts propose; Codex or an optional Luna planner performs semantic moves after safety review.
6. Re-run validation and inspect the final diff.

## Usage Marker

Keep one globally unique marker near each stable entry point. Existing markers remain valid; `tier` and `pinned` are optional.

```html
<!-- usage:agent.area.topic count=0 since=YYYY-MM-DD last=never tier=detail pinned=false -->
```

```powershell
# Short read-only report
./scripts/run_memory_steward.ps1 -RepoRoot <repo>

# Record one entry that was actually used
./scripts/run_memory_steward.ps1 -RepoRoot <repo> -TouchId agent.area.topic -Quiet

# Full machine-readable inventory for targeted filtering
./scripts/run_memory_steward.ps1 -RepoRoot <repo> -OutputFormat Json
```

## Layering Defaults

- `root`: `agent.md`, target at most 80 lines; pinned safety rules and highest-value routes only.
- `index`: category routing, target at most 80 lines; one-line summary, keywords, and links.
- `detail`: one independently recallable topic, at most 120 lines and 12 KiB.
- `archive`: low-use historical memory that remains linked but is excluded from normal recall.

`pinned=true` prevents automatic demotion. Usage-based recommendations use `count`, `since`, and `last`; they never silently delete or move content.

## Resources

- Read `references/workflow.md` for the end-to-end stewardship sequence.
- Read `references/tiering.md` only when promoting, demoting, or pinning memory.
- Read `references/splitting.md` only when a file is oversized or mixes several concrete topics.
- Read `references/llm_tradeoffs.md` before changing script/LLM responsibilities.
- Use `scripts/run_memory_steward.ps1`; it writes a report only when `-ReportRoot <dir>` is explicitly supplied.

## Boundaries

- Do not store secrets, credentials, or raw private transcript dumps in memory docs.
- Do not infer usage from full chat logs. Increment only an entry that was actually read and used.
- Do not auto-commit, auto-push, or switch the user's project worktree. Publishing this skill's own repository is allowed only when the user explicitly requests it.
- Do not run interactive analysis pipelines as unattended memory stewardship.
- Do not let Luna or another LLM directly rewrite files from raw logs. Filter locally, generate a plan, review it, then edit and validate.
