---
name: codex-memory-steward
description: Steward progressive Codex project memory systems. Use when Codex needs to create or update project-root agent.md/.agent memory docs, record stable lessons before context compression, summarize local Codex session records, or export this memory workflow as a reusable skill.
---

# Codex Memory Steward

Use this skill to steward long-running Codex project memory without letting useful operational knowledge drift or sprawl. Store project memory in the active session's project folder, with `agent.md` at the project root plus progressively disclosed `.agent/` reference files.

## Optimized Workflow

Use a two-lane process: scripts handle deterministic collection, while the LLM handles semantic judgment and rewriting.

1. Identify the active session's project folder first. Use the current working directory unless the user names another project root.
2. Directly create or update that folder's memory system: `<project-root>/agent.md`, `<project-root>/.agent/`, and `<project-root>/.agent/project_inventory.md`.
3. Run a deterministic scan for project-root `agent.md`, project-local `.agent/`, `AGENTS.md`, README files, usage markers, file inventory, and session records.
4. Ask the LLM to triage scan output into stable lessons, one-off noise, risks, and action items.
5. Keep `<project-root>/agent.md` under 200 lines; move details into `<project-root>/.agent/` or another project-local hidden memory directory.
6. Add one usage marker near each stable entry point:

```html
<!-- usage:agent.area.topic count=0 since=YYYY-MM-DD last=never -->
```

7. Before context compression at about four fifths of the window, update memory docs with stable new lessons, then summarize.
8. Validate with the bundled script or the repository's own memory checker, then re-read the diff for hallucinated or over-broad memories.

## Resources

- Read `references/workflow.md` for detailed project-memory layout rules.
- Read `references/llm_tradeoffs.md` before redesigning the workflow or deciding what the LLM should automate.
- Use `scripts/run_memory_steward.ps1 -Apply` from the target project root, or pass `-RepoRoot`, so it creates/updates that project's `agent.md`, `.agent/project_inventory.md`, usage markers, and recent session report.

## Boundaries

- Do not store secrets, credentials, or raw private transcript dumps in memory docs.
- Do not put `agent.md` or `.agent/` under `~/.codex`; `.codex` is only a source for Codex session/history records.
- Do not auto-commit, auto-push, or switch the user's main worktree.
- Do not run interactive analysis pipelines as unattended memory stewardship.
- Do not let the LLM directly rewrite memory from raw logs without a deterministic scan and a final diff review.
