---
name: codex-memory-steward
description: Steward project-local Codex memory systems. Trigger only when the task explicitly involves agent.md/.agent memory hierarchy, usage markers (count/since/last), pre-compression memory curation, or migration/validation of memory-stat display layers.
---

# Codex Memory Steward

Use this skill to steward long-running Codex project memory without letting useful operational knowledge drift or sprawl. Store memory in the active project's folder with a short local `agent.md` plus progressively disclosed `.agent/` reference files.

## Trigger Signals (Use)

Use this skill when one or more high-confidence signals appear:
- The user explicitly mentions `agent.md`, `.agent/`, memory hierarchy/index, or usage markers.
- The task asks for context-compression prep by preserving stable lessons.
- The task asks to normalize usage-stat display between `agent.md` and `.agent/index.md`.
- The task asks to bootstrap a project-local memory system.

## Non-Trigger Signals (Do Not Use)

Do not use this skill for generic documentation editing, README polishing, or unrelated repo cleanup unless memory-stewardship goals are explicit.

## Decision Priority

When instructions conflict, apply this order:
1. User explicit instructions.
2. Existing repo-local convention in that memory root.
3. Default workflow in this skill.

## Core Rules

- Every `agent.md` owns an independent local memory system for its own directory.
- A parent `agent.md` normally indexes only sibling `.agent/*.md` and immediate child `agent.md` files.
- Shared cross-project information is an explicit exception; child-private details must stay in child memory roots.
- Exposure depth follows invocation frequency:
  - keep high-frequency facts shallow;
  - keep low-frequency facts deep in `.agent/`.
- `.agent/*.md` files with many independent facts should include a light local index and sub-point metadata (`count` / `since` / `last`).
- Usage statistics must live in exactly one Markdown display layer per memory root.
- Machine-readable stats (for example `.agent/stats/*.json`) may coexist, but human-readable stats must not be split across two Markdown layers.

## Optimized Workflow

Use a two-lane process: scripts handle deterministic collection; the LLM handles semantic judgment and rewriting.

1. Identify the active session project folder (cwd by default unless user provides another root).
2. Create/update that folder's memory system: `<project-root>/agent.md`, `<project-root>/.agent/`, `<project-root>/.agent/project_inventory.md`.
3. For nested workspaces, repeat locally so each nested `agent.md` has independent local stats.
4. Run deterministic scan for `agent.md`, project-local `.agent/`, `AGENTS.md`, README files, usage markers, file inventory, and session records.
5. Ask LLM triage: stable lessons, one-off noise, risks, action items.
6. Keep each `agent.md` concise (target under 200 lines). If over target, split details into `.agent/` and note why.
7. Add one usage marker near each stable entry point:

```html
<!-- usage:agent.area.topic count=0 since=YYYY-MM-DD last=never -->
```

8. Keep the human-readable frequency table in one display layer per memory root.
9. Before context compression (around 80% context usage), update memory docs with stable lessons, then summarize.
10. For dense `.agent/*.md` pages, maintain mini-index alignment with edit order to simplify incremental promotion.
11. Validate with script/checker, then re-read diff for hallucinated or over-broad memory.

## Migration SOP (Stats Display Layer)

When both `agent.md` and `.agent/index.md` currently display human-readable stats:
1. Detect duplicate display sections.
2. Pick the target display layer (default: `agent.md` unless repo convention says otherwise).
3. Move/merge display table to target layer.
4. Replace non-target display with navigation link only.
5. Preserve machine-readable stats files untouched.

## Validation with Repair Actions

- Check: every relevant `agent.md` has usage marker + local stats/usage section.
  - Repair: add missing marker/section with minimal seed rows.
- Check: parent `agent.md` has no direct child-private deep links.
  - Repair: relink to child `agent.md` or explicitly mark shared page scope.
- Check: human-readable stats appear in exactly one Markdown layer.
  - Repair: keep target layer; replace other layer's table with link.
- Check: secrets/credentials/raw private transcripts absent.
  - Repair: redact and replace with safe operational summary.
- Check: existing custom stats systems preserved unless user requests migration.
  - Repair: keep machine-readable pipeline, normalize Markdown display only.

## Output Contract

Always produce a compact result block:
- Changed files.
- Stable lessons added/updated.
- Risks and ambiguities.
- Follow-up actions.

## Resources

- Read `references/workflow.md` for detailed layout rules.
- Read `references/llm_tradeoffs.md` before redesigning automation boundaries.
- Use `scripts/run_memory_steward.ps1 -Apply` from target root, or pass `-RepoRoot`.

## Boundaries

- Do not store secrets, credentials, or raw private transcript dumps in memory docs.
- Do not put `agent.md` or `.agent/` under `~/.codex`.
- Do not auto-commit, auto-push, or switch the user's main worktree.
- Do not run interactive analysis pipelines as unattended memory stewardship.
- Do not let the LLM rewrite memory from raw logs without deterministic scan + final diff review.
