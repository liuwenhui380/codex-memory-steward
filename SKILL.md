---
name: codex-memory-steward
description: Steward progressive Codex project memory systems. Use when Codex needs to create or update project-root agent.md/.agent memory docs, record stable lessons before context compression, summarize local Codex session records, or export this memory workflow as a reusable skill.
---

# Codex Memory Steward

Use this skill to steward long-running Codex project memory without letting useful operational knowledge drift or sprawl. Store project memory in the project folder, with `agent.md` at the project root plus progressively disclosed `.agent/` reference files.

## Optimized Workflow

Use a two-lane process: scripts handle deterministic collection, while the LLM handles semantic judgment and rewriting.

1. Identify the project root first, then run a deterministic scan for project-root `agent.md`, project-local `.agent/`, `AGENTS.md`, README files, usage markers, and session records.
2. Ask the LLM to triage scan output into stable lessons, one-off noise, risks, and action items.
3. Keep `<project-root>/agent.md` under 200 lines; move details into `<project-root>/.agent/` or another project-local hidden memory directory.
4. Add one usage marker near each stable entry point:

```html
<!-- usage:agent.area.topic count=0 since=YYYY-MM-DD last=never -->
```

5. Before context compression at about four fifths of the window, update memory docs with stable new lessons, then summarize.
6. Validate with the bundled script or the repository's own memory checker, then re-read the diff for hallucinated or over-broad memories.

## Resources

- Read `references/workflow.md` for detailed project-memory layout rules.
- Read `references/llm_tradeoffs.md` before redesigning the workflow or deciding what the LLM should automate.
- Use `scripts/run_memory_steward.ps1` from the target project root, or pass `-RepoRoot`, so it checks that project's `agent.md`, `.agent/`, usage markers, and recent session records.

## Boundaries

- Do not store secrets, credentials, or raw private transcript dumps in memory docs.
- Do not put `agent.md` or `.agent/` under `~/.codex`; `.codex` is only a source for Codex session/history records.
- Do not auto-commit, auto-push, or switch the user's main worktree.
- Do not run interactive analysis pipelines as unattended memory stewardship.
- Do not let the LLM directly rewrite memory from raw logs without a deterministic scan and a final diff review.
