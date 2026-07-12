# Progressive Memory Workflow

## File Roles

- `<project-root>/agent.md`: safety-critical rules and highest-value routes, target at most 80 lines; never place it in `~/.codex`.
- `<project-root>/.agent/*.md`: category indexes, target at most 80 lines each.
- `<project-root>/.agent/memory_parts/*.md`: one independently recallable topic, at most 120 lines and 12 KiB.
- `<project-root>/.agent/archive/*.md`: linked historical memory excluded from normal recall.
- `<project-root>/.agent/project_inventory.md`: generated file tree plus rough content map for files under the project folder.
- `AGENTS.md`: repository coding and collaboration rules.
- `README.md`: user-facing project usage docs.

## Hierarchical Indexing

- Treat each directory with an `agent.md` as an independent memory root.
- A local `agent.md` normally indexes only:
  - its own sibling `.agent/*.md` files;
  - immediate child directories' `agent.md` files.
- A local `agent.md` must not index project-private:
  - immediate child `.agent/*.md` files;
  - grandchild `agent.md` files;
  - deeper run/result memory pages.
- Put a short rule in the parent `agent.md` explaining that deeper memory is discovered by opening the child `agent.md` first.
- When a child project lacks a `.agent/` layer but needs local detail, create the smallest useful `.agent/index.md` and keep it navigation-only unless the project chooses index-based stats.

## Shared Cross-Project Information

When one folder contains several child projects, common information may be promoted to the parent memory layer. This is an exception to the normal no-cross-level rule.

Write shared information in the parent `agent.md` when it is short and affects multiple children, for example:

- shared servers, domains, ports, SSH key locations, reverse-proxy topology, or database/Redis topology;
- shared credential hygiene rules, such as where plaintext passwords must not be stored;
- shared Windows/Codex tool constraints, such as `rg.exe` fallback behavior;
- shared usage-statistics policy for all child `agent.md` files;
- shared automation or compression rules.

If the shared note is longer than a few bullets, put it under the parent `.agent/`, such as `.agent/shared_operations.md`, and link that parent-owned file from the parent `agent.md`.

Direct links from a parent `agent.md` into `child/.agent/*.md` are allowed only when the target page is explicitly marked as shared across multiple child projects and the parent entry says why it is shared. Do not use this exception for ordinary child-private runbooks, incidents, or implementation details.

## Usage Statistics Placement

Choose one Markdown display layer per memory root:

1. Preferred: `agent.md` owns the human-readable `count/since/last` table.
2. Alternative: `.agent/index.md` owns the table, but then `agent.md` must not duplicate it.

Do not mix these within one memory system. Machine-readable stats files such as `.agent/stats/*.json`, `.agent/stats/*.jsonl`, or `.agent/metrics/*.json` may remain as sources of truth or automation outputs, but the human-readable summary should appear in one Markdown place only.

## What To Write

- Stable user preferences that change future behavior.
- Repeated mistakes and their fixes.
- Project-specific workflow constraints.
- Paths that are hard to rediscover and matter for future work.

## What Not To Write

- One-off command output.
- Unverified guesses.
- Secrets or raw private transcript dumps.
- Details obvious from the code.
- Rolling logs that would create noisy diffs.

## Minimal Recall Pass

1. Run `run_memory_steward.ps1` and inspect the compact report.
2. Read `agent.md` first.
3. Select one matching category index from its route and read only that file.
4. If needed, select one concrete topic file from the index.
5. When a marker-bearing entry materially affects the task, call the scanner with its `-TouchId` once.
6. Use `-OutputFormat Json` when exact filtering is needed; do not enlarge the default report.

## Optimized Stewardship Pass

Use this order to match LLM strengths and weaknesses:

1. **Resolve root**: use the active session folder as `<project-root>` unless the user names another root.
2. **Apply scaffold**: run `scripts/run_memory_steward.ps1 -Apply` from that folder, or pass `-RepoRoot`, to create/update `agent.md`, `.agent/`, and `.agent/project_inventory.md`.
3. **Collect**: count lines, find usage markers, list changed files, refresh file inventory, and sample session records.
4. **Classify**: let the LLM group findings into stable rules, temporary noise, risks, and unknowns.
5. **Edit**: rewrite memory in concise project language, preserving hierarchy and stats placement. Prefer Simplified Chinese for Chinese projects; keep paths, commands, API names, and commit IDs unchanged.
6. **Validate**: run deterministic checks again.
7. **Review**: inspect the final diff for over-generalization, accidental secrets, or raw transcript leakage.

## Compression Checkpoint

When the context window approaches four fifths:

1. List new stable lessons from the current session.
2. Add them to the appropriate project-local detailed memory page.
3. Update `agent.md` only if the root needs a pinned rule or a high-value route.
4. Refresh `.agent/project_inventory.md` if project files changed.
5. Preserve or add usage markers with `count`, `since`, `last`, and optional `tier`/`pinned`.
6. Run the memory checker.
7. Then compress or summarize the session.

Do not wait until after compression to update memory; the most useful details are easiest to separate from noise while the full session is still available.

## Location Rule

Project memory belongs to the project, not the Codex home directory. Use `~/.codex` only as an input source for session records such as `sessions`, `archived_sessions`, or `history.jsonl`; never create or update `~/.codex/agent.md` as project memory.

## Project Inventory

Each skill invocation should keep `.agent/project_inventory.md` current. The file lists project files, byte sizes, and a rough content summary so later agents can orient quickly before opening files. Exclude generated or noisy folders such as `.git`, `.agent`, caches, dependency directories, and build output.

## Usage-Based Layering

- Treat `count` as a proxy for how often an entry point is used.
- Treat `since` as the start date for the measurement window.
- Treat `last` as the recency signal.
- Use `count` together with the observation window starting at `since`; lifetime count alone is not frequency.
- Preserve high-density and recently used entries first.
- Pin safety-critical entries so low use never hides them.
- Convert only after semantic review: root -> index -> detail -> archive. Never delete merely because use is low.
- When a file exceeds its threshold or mixes independent topics, follow `splitting.md` even when every topic belongs to the same broad category.
- Keep the frequency table in the selected Markdown layer for that memory root; if the project standardizes on `agent.md`, `.agent/index.md` should remain pure navigation.

## Deterministic Checks

Use PowerShell-native scanning when `rg.exe` is unavailable or blocked:

- Find `agent.md` files, excluding `.git`, dependency, cache, build, `work`, and `artifacts` folders.
- For each `agent.md`, verify one usage marker and a local stats section.
- For each `.agent/index.md`, verify there are no stats terms if stats live in `agent.md`: `Count`, `Last`, `call_count`, `last_called`, `usage:`, `有效调用`, `调用次数`.
- For parent `agent.md`, search for cross-level patterns such as `child/.agent/` and `child/grandchild/agent.md`; allow them only when the entry is explicitly labeled shared and applies to multiple children.
- Scan memory docs for known plaintext secrets before finishing.
