# Codex Memory Steward

[中文说明](README-ZH.md)

Codex Memory Steward is a reusable Codex skill and workflow for maintaining project-local memory systems. It helps long-running Codex work preserve stable lessons, operating rules, and file maps without turning chat history into noisy documentation.

## When This Skill Should Trigger

Use this skill when at least one high-confidence signal is present:
- The task explicitly mentions `agent.md`, `.agent/`, memory hierarchy/index, or usage markers.
- The task asks for pre-compression memory curation.
- The task asks to normalize human-readable stats display between `agent.md` and `.agent/index.md`.
- The task asks to bootstrap a local memory system.

## When It Should Not Trigger

Do not use this skill for generic docs editing, README polishing, or unrelated repository cleanup when memory-stewardship goals are not explicit.

## Decision Priority

If instructions conflict, apply this order:
1. User explicit instruction.
2. Existing repo-local convention in that memory root.
3. Default policy in `SKILL.md`.

## What It Manages

- `agent.md`: the local memory entry point for the current directory.
- `.agent/*.md`: detailed memory pages for local rules, incidents, inventories, and compression notes.
- `.agent/project_inventory.md`: generated project file inventory and rough content map.
- Usage markers: lightweight `count`, `since`, and `last` metadata for deciding what should stay shallow.
- Session-derived lessons: durable findings extracted from Codex session records, not raw transcript dumps.

## Workflow Highlights

1. Resolve the active project root (cwd by default unless user names another root).
2. Run deterministic scanning first; let the LLM perform semantic triage.
3. Keep `agent.md` and category indexes near 80 lines; keep concrete-topic detail files under 120 lines and 12 KiB.
4. Display human-readable usage stats in exactly one Markdown layer per memory root.
5. Increment an entry only after it is actually used; frequency, recency, and safety pinning drive tier recommendations.
6. Split oversized files by independently recallable topic, even inside one broad category.
7. Validate hierarchy, marker coverage, stats placement, links, encoding, and secret hygiene before finishing.

## Migration SOP (Stats Display Layer)

If both `agent.md` and `.agent/index.md` display human-readable stats:
1. Detect duplicate display blocks.
2. Choose a target layer (default `agent.md` unless repo convention says otherwise).
3. Merge/move display table into the target layer.
4. Replace non-target table with navigation-only link.
5. Preserve machine-readable stats files unchanged.

## Usage-Tiered Recall

- `-TouchId` increments one globally unique entry without parsing full chat logs.
- `-Quiet` records use without loading another report into context.
- Default Markdown is compact; JSON retains the full inventory for exact filtering.
- Touch uses a repository lock, strict UTF-8 validation, and atomic replacement.
- Optional Luna planning may propose semantic splits from locally filtered content; deterministic checks validate the result.

## Output Contract

Each skill execution should return:
- Changed files
- Stable lessons added/updated
- Risks and ambiguities
- Follow-up actions

## Repository Layout

```text
.
|-- SKILL.md
|   `-- Codex skill entry point and operating boundaries.
|
|-- agents/
|   `-- openai.yaml
|       `-- Display metadata, default prompt, and version.
|
|-- references/
|   |-- workflow.md
|   |   `-- Detailed hierarchy, stats-placement, and validation rules.
|   |
|   |-- tiering.md
|   |   `-- Usage counting, safety pinning, and root/index/detail/archive recommendation rules.
|   |
|   |-- splitting.md
|   |   `-- Concrete-topic split boundaries, optional Luna plans, and post-split validation.
|   |
|   `-- llm_tradeoffs.md
|       `-- Guidance on what scripts should do and what the LLM should judge.
|
|-- scripts/
|   `-- run_memory_steward.ps1
|       `-- PowerShell scanner/bootstrapper that reports, touches, ranks, inventories, and identifies oversized memory.
|
|-- tests/
|   `-- run_tests.ps1
|       `-- Dependency-free regression tests for counters, concurrency, encoding, tiers, inventory, and size boundaries.
|
`-- CHANGELOG.md
    `-- Cumulative version history.
```

## Quick Start

```powershell
# Bootstrap/update project-local memory and inventory
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project -Apply

# Compact, read-only report
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project

# Record a memory entry that was actually used
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project -TouchId agent.area.topic -Quiet

# Full inventory for precise filtering or automation
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project -OutputFormat Json

# Run the dependency-free regression suite
./tests/run_tests.ps1
```

The scanner never moves or deletes memory. Touch updates one ID at a time with a repository lock, strict UTF-8 validation, and atomic replacement. It reports tier changes and oversized files; Codex or an optional Luna planner performs semantic splitting only after local secret filtering and diff review. New memory follows the user's/project's language, with concise Simplified Chinese preferred for Chinese workflows.

## Guardrails

- Do not write project memory under `~/.codex`; use that location only as an input source for session records.
- Do not store secrets, credentials, tokens, or raw private transcripts in memory docs.
- Do not link from a parent `agent.md` into child `.agent/` details unless the target page is explicitly shared across multiple children.
- Do not split human-readable usage statistics between `agent.md` and `.agent/index.md` in the same memory root.
