# LLM Tradeoffs For Memory Stewardship

## Use LLMs For

- Semantic compression: turn long sessions into short stable rules.
- Cross-file synthesis: connect README, AGENTS, `agent.md`, and hidden memory pages.
- Relevance judgment: decide whether a lesson will matter in future sessions.
- Rewriting: make memory concise, warm, and project-specific.
- Risk spotting: notice privacy leaks, contradictory rules, or scope creep.

## Do Not Rely On LLMs For

- Exact counts, timestamps, branch lists, or marker inventories.
- Parsing huge raw logs without pre-filtering.
- Safely handling secrets in raw transcripts.
- Distinguishing temporary debug output from durable rules without evidence.

## Design Rule

Let scripts produce facts and small candidate sets. Let the LLM decide meaning, rewrite docs, and explain tradeoffs. Then run scripts again to verify facts.

## Practical Heuristics

- If the task is repetitive, fragile, or format-sensitive, put it in a script.
- If the task requires judgment, context, or wording, give it to the LLM.
- If the task changes machine state outside the repo, require explicit user approval.
- If the source is a raw session log, summarize candidates first; never paste entire transcripts into memory docs.
- If the LLM writes a new rule, it should be specific enough to change future behavior.
- If compressing memory docs, use `count`, `since`, and `last` as evidence, but let the LLM check whether a low-frequency entry is safety-critical before removing it.

## Failure Modes To Check

- Over-memory: storing too many one-off details.
- Under-memory: compressing away a real user preference or repeated pitfall.
- Privacy leak: copying raw paths, tokens, or private transcript text unnecessarily.
- Drift: root memory grows past 200 lines while detailed pages stay unused.
