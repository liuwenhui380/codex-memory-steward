---
name: codex-memory-steward
description: Steward progressive Codex project memory systems. Use when Codex needs to create or update project-root agent.md/.agent memory docs, nested agent.md indexes, usage-count statistics, record stable lessons before context compression, summarize local Codex session records, or export this memory workflow as a reusable skill.
---

# Codex Memory Steward

Use this skill to steward long-running Codex project memory without letting useful operational knowledge drift or sprawl. Store project memory in the active session's project folder, with a short local `agent.md` plus progressively disclosed `.agent/` reference files.

## Core Rules

- Every `agent.md` owns an independent local memory system for its own directory.
- A parent `agent.md` normally indexes only its own sibling `.agent/*.md` files and immediate child directories' `agent.md` files.
- Shared cross-project information is an explicit exception: if several child projects under one folder use the same server, credential-handling rule, deployment topology, tool policy, or usage-stat convention, write the short shared fact directly in the parent `agent.md` or put it in the parent `.agent/` and link it there.
- Do not cross levels for project-private details: a root `agent.md` must not directly index `child/.agent/*.md`, `child/grandchild/agent.md`, or deeper memory pages unless the linked page is explicitly marked as shared across multiple children.
- Each child `agent.md` continues the chain and indexes its own local `.agent/` details.
- Exposure depth should follow invocation frequency:
  - keep high-frequency entries shallow (promote stable facts into shallower pages);
  - keep low-frequency facts deep (`.agent/`) until usage proves promotion value.
- `.agent/*.md` files that contain many independent facts should add a light local index (目录) and invocation metadata (`count` / `since` / `last`) for each sub-point, so future edits can promote or refresh one point without full file reshaping.
- Usage statistics must live in exactly one Markdown layer per memory system. Default to putting human-readable `count/since/last` tables in that directory's `agent.md`; keep `.agent/index.md` as navigation only.
- Machine-readable stats files such as `.agent/stats/*.json` may exist, but the Markdown statistics display should not be split between `agent.md` and `.agent/index.md`.

## Optimized Workflow

Use a two-lane process: scripts handle deterministic collection, while the LLM handles semantic judgment and rewriting.

1. Identify the active session's project folder first. Use the current working directory unless the user names another project root.
2. Directly create or update that folder's memory system: `<project-root>/agent.md`, `<project-root>/.agent/`, and `<project-root>/.agent/project_inventory.md`.
3. For nested workspaces, repeat locally: each nested `agent.md` gets its own `.agent/` and local stats table.
4. Run a deterministic scan for `agent.md` files, project-local `.agent/` files, `AGENTS.md`, README files, usage markers, file inventory, and session records.
5. Ask the LLM to triage scan output into stable lessons, one-off noise, risks, and action items.
6. Keep each `agent.md` under 200 lines; move details into that directory's `.agent/` or another project-local hidden memory directory.
7. Add one usage marker near each stable entry point:

```html
<!-- usage:agent.area.topic count=0 since=YYYY-MM-DD last=never -->
```

8. Put the human-readable frequency table in `agent.md` unless the project explicitly standardizes on `.agent/index.md`; never mix both within one memory system.
9. Before context compression at about four fifths of the window, update memory docs with stable new lessons, then summarize.
10. For `.agent/*.md` pages with dense point lists, update a mini-index of sub-entries with `count/since/last` and keep that index aligned with edit order; this enables moving one hot point upward first.
11. Validate with the bundled script or the repository's own memory checker, then re-read the diff for hallucinated or over-broad memories.

## Validation Checklist

- Every relevant `agent.md` has a usage marker and a local stats/usage section.
- Root or parent `agent.md` files do not directly link to descendant `.agent/` files or deeper `agent.md` files, except for explicitly marked shared pages used by multiple child projects.
- If stats are standardized in `agent.md`, `.agent/index.md` files contain no `Count`, `Last`, `usage`, `有效调用`, or `调用次数` display.
- If stats are standardized in `.agent/index.md`, `agent.md` links there and does not duplicate stats.
- Secrets, API keys, passwords, tokens, raw transcripts, and private credentials are absent from memory docs.
- Existing custom statistics systems are preserved unless the user asks to migrate them; normalize the Markdown display layer without deleting machine-readable stats.

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
