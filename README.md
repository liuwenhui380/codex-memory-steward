# Codex Memory Steward

Codex Memory Steward is a reusable Codex skill for keeping long-running project memory concise, structured, and useful across sessions.

It helps teams maintain `agent.md`, `.agent/`, `AGENTS.md`, and related memory docs without turning them into raw transcript dumps or stale rule piles.

## Why This Exists

Long Codex sessions accumulate important lessons: user preferences, repeated mistakes, project-specific constraints, and workflow details that are hard to rediscover. The challenge is preserving those lessons without storing noisy logs or overfitting future agents to one-off events.

This skill uses a two-lane workflow:

- deterministic scripts collect facts, counts, markers, and recent session candidates;
- the LLM applies judgment, rewrites concise memory entries, and checks whether a lesson is durable.

## What It Does

- Scans `agent.md`, `.agent/`, `AGENTS.md`, `README.md`, and recent Codex session records.
- Reports line counts, usage markers, and compression-priority candidates.
- Encourages progressive disclosure: a short root memory file with detail pages underneath.
- Preserves usage markers such as `<!-- usage:agent.area.topic count=0 since=YYYY-MM-DD last=never -->`.
- Separates stable lessons from temporary debugging noise.
- Provides guardrails against secrets, private transcript leakage, and broad hallucinated policy.

## Repository Layout

```text
.
|-- SKILL.md
|-- agents/
|   `-- openai.yaml
|-- references/
|   |-- llm_tradeoffs.md
|   `-- workflow.md
`-- scripts/
    `-- run_memory_steward.ps1
```

## Installation

Copy this directory into your Codex skills directory:

```powershell
Copy-Item -Recurse . "$env:USERPROFILE\.codex\skills\codex-memory-steward"
```

Then ask Codex to use the skill:

```text
Use $codex-memory-steward to update project memory before compressing this session.
```

## Usage

From the repository you want to inspect, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_memory_steward.ps1 -RepoRoot .
```

The script writes a Markdown report to a desktop log directory by default. Codex can then use that report to decide what belongs in long-term memory and what should be ignored.

## Recommended Workflow

1. Run the memory steward script for deterministic context.
2. Ask Codex to classify findings into stable lessons, noise, risks, and action items.
3. Keep `agent.md` short, ideally under 200 lines.
4. Move detailed operational notes into `.agent/*.md`.
5. Preserve usage markers and update them intentionally.
6. Re-run the script and review the diff before committing memory changes.

## Boundaries

Do not store secrets, credentials, raw private transcripts, or one-off command output in memory docs. This project is designed to support judgment, not replace it.

## License

MIT
