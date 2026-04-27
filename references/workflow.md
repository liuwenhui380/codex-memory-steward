# Progressive Memory Workflow

## File Roles

- `agent.md`: short memory index for the current project, capped at 200 lines.
- `.agent/*.md`: detailed memory pages for domain rules, mistakes, compression, and usage markers.
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

## Optimized Pass Order

Use this order to match LLM strengths and weaknesses:

1. **Collect**: run scripts to count lines, find usage markers, list changed files, and sample session records.
2. **Classify**: let the LLM group findings into stable rules, temporary noise, risks, and unknowns.
3. **Edit**: let the LLM rewrite memory docs in concise, project-specific language.
4. **Validate**: run deterministic checks again.
5. **Review**: inspect the final diff for over-generalization, accidental secrets, or raw transcript leakage.

## Compression Checkpoint

When the context window approaches four fifths:

1. List new stable lessons from the current session.
2. Add them to the appropriate detailed memory page.
3. Update `agent.md` only if the root index needs a new short reminder.
4. Preserve or add usage markers with `count`, `since`, and `last`.
5. Run the memory checker.
6. Then compress or summarize the session.

Do not wait until after compression to update memory; the most useful details are easiest to separate from noise while the full session is still available.

## Usage-Based Compression

- Treat `count` as a proxy for how often an entry point is used.
- Treat `since` as the start date for the measurement window.
- Treat `last` as the recency signal.
- Preserve high-count and recently used entries first.
- Compress or demote entries with old `since`, low `count`, and `last=never`, after checking they are not safety-critical.
