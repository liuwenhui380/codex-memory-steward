---
name: codex-memory-steward
description: Steward project-local Codex memory systems with explicit usage counting, minimal recall routes, tier recommendations, and concrete-topic file splitting. Trigger only when the task explicitly involves agent.md/.agent hierarchy, usage markers (count/since/last), pre-compression memory curation, stats-display migration, validation, promotion/demotion/archive, or oversized-memory splitting.
---

# Codex Memory Steward

Steward long-running project memory with the smallest useful recall path. Scripts collect facts and update explicit counters; the LLM decides meaning, wording, and semantic file boundaries.

## Trigger Boundary

- Use only for explicit project-memory work: `agent.md`, `.agent/`, usage counters, compression prep, memory bootstrapping, stats-display migration, or semantic splitting.
- Do not trigger for generic documentation, README polishing, or unrelated repository cleanup.

## Decision Priority

When instructions conflict, apply this order:
1. User explicit instructions.
2. Existing repo-local convention in that memory root.
3. Default workflow in this skill.

## Core Rules

- Every `agent.md` owns an independent local memory system for its own directory.
- Store memory in the active project, not under `~/.codex`; parent memory normally links only sibling `.agent/` and immediate child `agent.md` files.
- Shared cross-project information is an explicit exception; child-private details must stay in child memory roots.
- Keep high-frequency facts shallow and low-frequency facts deep; split dense files by independently recallable topic.
- Usage statistics must live in exactly one Markdown display layer per memory root.
- Machine-readable stats may coexist, but human-readable stats must not be duplicated across Markdown layers.

## Minimal Recall Workflow

1. Identify the active project root. Use `-Apply` only when bootstrapping/updating its local `agent.md` and `.agent/project_inventory.md`.
2. Run the deterministic scanner. Use Markdown for a short report or JSON for exact filtering.
3. Read `agent.md`, then at most one matching index and one matching detail file; do not preload a whole category.
4. After an entry changes the current decision/action, record it with `-TouchId ... -Quiet`; the user does not update counters manually.
5. Classify stable lessons versus one-off noise. Follow the user/project language; prefer concise Simplified Chinese for Chinese projects while preserving technical identifiers.
6. Review tier and oversized-file recommendations. Scripts propose; Codex or optional Luna performs semantic moves after safety review.
7. Keep human-readable frequency statistics in exactly one display layer; preserve existing machine-readable stats.
8. Before compression, record stable lessons, then rerun validation and inspect the diff.

## Usage Marker

Keep one globally unique marker near each stable entry point. Existing markers remain valid; `tier` and `pinned` are optional.

```html
<!-- usage:agent.area.topic count=0 since=YYYY-MM-DD last=never tier=detail pinned=false -->
```

```powershell
# Bootstrap/update project-local memory and inventory
./scripts/run_memory_steward.ps1 -RepoRoot <repo> -Apply

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

## Stats Display Migration

When both `agent.md` and `.agent/index.md` display human-readable stats:

1. Detect duplicate display sections.
2. Keep one target layer (default `agent.md` unless local convention differs).
3. Replace the other table with a navigation link.
4. Preserve machine-readable stats files.

## Resources

- Read `references/workflow.md` for the end-to-end stewardship sequence.
- Read `references/tiering.md` only when promoting, demoting, or pinning memory.
- Read `references/splitting.md` only when a file is oversized or mixes several concrete topics.
- Read `references/llm_tradeoffs.md` before changing script/LLM responsibilities.
- Use `scripts/run_memory_steward.ps1`; it writes a report only when `-ReportRoot <dir>` is explicitly supplied.

## Output Contract

Return only changed files, stable lessons, risks/ambiguities, and follow-up actions.

## Boundaries

- Do not store secrets, credentials, or raw private transcript dumps in memory docs.
- Do not infer usage from full chat logs. Increment only an entry that was actually read and used.
- Do not put `agent.md` or `.agent/` under `~/.codex`.
- Do not auto-commit, auto-push, or switch the user's project worktree. Publishing this skill's own repository is allowed only when the user explicitly requests it.
- Do not run interactive analysis pipelines as unattended memory stewardship.
- Do not let Luna or another LLM directly rewrite files from raw logs. Filter locally, generate a plan, review it, then edit and validate.
