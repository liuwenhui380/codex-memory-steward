---
name: codex-memory-steward
description: Steward progressive Codex project memory systems. Use when Codex needs to create or update agent.md/.agent memory docs, record stable lessons before context compression, summarize local Codex session records, or export this memory workflow as a reusable skill.
---

# Codex Memory Steward

Use this skill to steward long-running Codex project memory without letting useful operational knowledge drift or sprawl. Prefer a short root memory file plus progressively disclosed reference files.

## Optimized Workflow

Use a two-lane process: scripts handle deterministic collection, while the LLM handles semantic judgment and rewriting.

1. Run a deterministic scan for `agent.md`, `AGENTS.md`, `.agent/`, README files, usage markers, and session records.
2. Ask the LLM to triage scan output into stable lessons, one-off noise, risks, and action items.
3. Keep the root memory file under 200 lines; move details into `.agent/` or another hidden memory directory.
4. Add one usage marker near each stable entry point:

```html
<!-- usage:agent.area.topic count=0 since=YYYY-MM-DD last=never -->
```

5. Before context compression at about four fifths of the window, update memory docs with stable new lessons, then summarize.
6. Validate with the bundled script or the repository's own memory checker, then re-read the diff for hallucinated or over-broad memories.

## Resources

- Read `references/workflow.md` for detailed project-memory layout rules.
- Read `references/llm_tradeoffs.md` before redesigning the workflow or deciding what the LLM should automate.
- Use `scripts/run_memory_steward.ps1` as a generic checker for `agent.md`, `.agent/`, usage markers, and recent session records.

## Boundaries

- Do not store secrets, credentials, or raw private transcript dumps in memory docs.
- Do not auto-commit, auto-push, or switch the user's main worktree.
- Do not run interactive analysis pipelines as unattended memory stewardship.
- Do not let the LLM directly rewrite memory from raw logs without a deterministic scan and a final diff review.
