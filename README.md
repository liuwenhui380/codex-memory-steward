# Codex Memory Steward

[中文说明](README-ZH.md)

Codex Memory Steward is a reusable Codex skill and workflow for maintaining project-local memory systems. It helps long-running Codex work preserve stable lessons, operating rules, and file maps without turning chat history into noisy documentation.

The core idea is simple: project memory belongs inside the project. A short `agent.md` gives future agents the high-frequency facts first, while local `.agent/` pages hold deeper detail that can be opened only when needed.

## What It Manages

- `agent.md`: the local memory entry point for the current directory.
- `.agent/*.md`: detailed memory pages for local rules, incidents, inventories, and compression notes.
- `.agent/project_inventory.md`: generated project file inventory and rough content map.
- Usage markers: lightweight `count`, `since`, and `last` metadata for deciding what should stay shallow.
- Session-derived lessons: durable findings extracted from Codex session records, not raw transcript dumps.

## Memory Model

Each directory with an `agent.md` is treated as its own memory root.

A parent `agent.md` normally links only to its own `.agent/*.md` files and immediate child directories' `agent.md` files. Child-private details stay inside the child memory system. Shared cross-project facts, such as a common server topology, credential rule, tool policy, or usage-stat convention, can be promoted to the parent layer when they affect multiple children.

Usage statistics should be displayed in one Markdown layer per memory root. The default is to keep the human-readable `count/since/last` table in `agent.md` and keep `.agent/index.md` as navigation only.

## Workflow

1. Resolve the active project root from the current working directory unless a user names another path.
2. Run deterministic scanning before rewriting memory.
3. Let the LLM classify scan output into durable lessons, temporary noise, risks, and follow-ups.
4. Update the local `agent.md` and `.agent/` pages with concise, project-specific entries.
5. Keep root entry files short, usually under 200 lines.
6. Validate usage markers, hierarchy, inventory freshness, and secret hygiene before finishing.

The workflow intentionally separates deterministic collection from semantic judgment. Scripts collect verifiable facts; the LLM decides what is worth preserving and how shallow it should live.

## Repository Layout

```text
.
|-- SKILL.md
|   `-- Codex skill entry point and operating boundaries.
|
|-- agents/
|   `-- openai.yaml
|       `-- Display metadata and default prompt for Codex.
|
|-- references/
|   |-- workflow.md
|   |   `-- Detailed hierarchy, stats-placement, and validation rules.
|   |
|   `-- llm_tradeoffs.md
|       `-- Guidance on what scripts should do and what the LLM should judge.
|
`-- scripts/
    `-- run_memory_steward.ps1
        `-- PowerShell scanner and optional memory-system bootstrapper.
```

## Guardrails

- Do not write project memory under `~/.codex`; use that location only as an input source for session records.
- Do not store secrets, credentials, tokens, or raw private transcripts in memory docs.
- Do not link from a parent `agent.md` into child `.agent/` details unless the target page is explicitly shared across multiple children.
- Do not split human-readable usage statistics between `agent.md` and `.agent/index.md` in the same memory root.
- Prefer PowerShell-native scanning on Windows when the bundled `rg.exe` path is blocked.

## When To Use

Use this skill when a Codex session produces lessons that should affect future work, when a project needs `agent.md` / `.agent/` bootstrapping, when context is about to be compressed, or when an existing memory tree needs hierarchy and usage-stat cleanup.
