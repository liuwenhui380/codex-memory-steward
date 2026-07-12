# Progressive Memory Workflow

## File Roles

- `agent.md`: safety-critical rules and highest-value routes, target at most 80 lines.
- `.agent/*.md`: category indexes, target at most 80 lines each.
- `.agent/memory_parts/*.md`: one independently recallable topic, at most 120 lines and 12 KiB.
- `.agent/archive/*.md`: linked historical memory excluded from normal recall.
- `AGENTS.md`: repository coding and collaboration rules.
- `README.md`: user-facing project usage docs.

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

1. **Collect**: run scripts to count lines, find usage markers, list changed files, and sample session records.
2. **Classify**: let the LLM group findings into stable rules, temporary noise, risks, and unknowns.
3. **Edit**: let the LLM rewrite memory docs in concise, project-specific language. Prefer Simplified Chinese when the user/project language is Chinese; do not translate paths, commands, API names, or commit IDs.
4. **Validate**: run deterministic checks again.
5. **Review**: inspect the final diff for over-generalization, accidental secrets, or raw transcript leakage.

## Compression Checkpoint

When the context window approaches four fifths:

1. List new stable lessons from the current session.
2. Add them to the appropriate detailed memory page.
3. Update `agent.md` only if the root needs a pinned rule or a high-value route.
4. Preserve or add usage markers with `count`, `since`, `last`, and optional `tier`/`pinned`.
5. Run the memory checker.
6. Then compress or summarize the session.

Do not wait until after compression to update memory; the most useful details are easiest to separate from noise while the full session is still available.

## Usage-Based Layering

- Treat `count` as a proxy for how often an entry point is used.
- Treat `since` as the start date for the measurement window.
- Treat `last` as the recency signal.
- Use `count` together with the observation window starting at `since`; lifetime count alone is not frequency.
- Preserve high-density and recently used entries first.
- Pin safety-critical entries so low use never hides them.
- Convert only after semantic review: root -> index -> detail -> archive. Never delete merely because use is low.
- When a file exceeds its threshold or mixes independent topics, follow `splitting.md` even when every topic belongs to the same broad category.
