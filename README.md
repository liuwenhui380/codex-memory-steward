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
3. Keep `agent.md` concise (target under 200 lines; overflow should be split into `.agent/` with rationale).
4. Display human-readable usage stats in exactly one Markdown layer per memory root.
5. Validate hierarchy, marker coverage, stats placement, and secret hygiene before finishing.

## Migration SOP (Stats Display Layer)

If both `agent.md` and `.agent/index.md` display human-readable stats:
1. Detect duplicate display blocks.
2. Choose a target layer (default `agent.md` unless repo convention says otherwise).
3. Merge/move display table into the target layer.
4. Replace non-target table with navigation-only link.
5. Preserve machine-readable stats files unchanged.

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
|   `-- llm_tradeoffs.md
|       `-- Guidance on what scripts should do and what the LLM should judge.
|
|-- scripts/
|   `-- run_memory_steward.ps1
|       `-- PowerShell scanner and optional memory-system bootstrapper.
|
`-- RELEASE_NOTES.md
    `-- Published release summaries.
```

## Guardrails

- Do not write project memory under `~/.codex`; use that location only as an input source for session records.
- Do not store secrets, credentials, tokens, or raw private transcripts in memory docs.
- Do not link from a parent `agent.md` into child `.agent/` details unless the target page is explicitly shared across multiple children.
- Do not split human-readable usage statistics between `agent.md` and `.agent/index.md` in the same memory root.
