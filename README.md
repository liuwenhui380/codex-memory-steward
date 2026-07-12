# Codex Memory Steward

Codex Memory Steward is a memory-management method and reusable Codex skill for long-running Codex projects. It turns stable, reusable lessons from development sessions into structured project memory.

The goal is not to save chat history. The goal is to preserve project knowledge that can shape future decisions across multi-step development, context compression, and cross-session collaboration.

## Core Principle

The method separates project-memory stewardship into two complementary stages:

1. Deterministic scanning

   Scripts collect verifiable facts first, such as `agent.md` line counts, `.agent/` detail pages, `AGENTS.md`, `README.md`, usage markers, and recent session-record locations. This gives the LLM stable input instead of relying on memory or impression.

2. Semantic judgment and compression

   The LLM reviews the scan output and decides which findings are durable lessons and which are one-off debugging noise. Stable lessons are compressed into concise entries and placed in the root memory file or detailed memory pages.

3. Progressive disclosure

   The root `agent.md` stays short and navigation-focused. Detailed operational knowledge lives in `.agent/*.md`, so future agents can read the most important constraints first and expand into details only when needed.

4. Usage-feedback markers

   Usage markers record `count`, `since`, and `last` metadata for memory entries. An entry is incremented only after it is actually used. Frequency, recency, and safety pinning produce evidence-backed root/index/detail/archive recommendations.

## Key Features

- Script and LLM division of labor: scripts collect facts, while the LLM handles semantic filtering and concise rewriting.
- Compression-aware workflow: stable lessons are captured before long-session context compression.
- Low-noise memory: the method favors rules that change future behavior instead of storing complete session history.
- Layered memory structure: a short root file points to hidden detail pages for deeper project knowledge.
- Usage-marker mechanism: frequency and recency become practical signals for memory compression.
- Explicit usage touch: `-TouchId` safely increments one globally unique memory entry without parsing full chat logs.
- Compact recall reports: the default output shows only the highest-value routes; JSON retains the full inventory for exact filtering.
- Concrete-topic splitting: root and index files target 80 lines; detail files target 120 lines and 12 KiB, even inside one broad category.
- Optional Luna planning: Luna can propose semantic split plans from locally filtered content, while deterministic scripts validate the result.
- Portable skill package: the approach is not tied to one project and can be reused across Codex repositories.

## Method Directory Structure

```text
.
|-- SKILL.md
|   `-- Codex skill entry point defining when to use the memory-stewardship method and its core workflow.
|
|-- agents/
|   `-- openai.yaml
|       `-- Skill display metadata, including display name, short description, and default prompt.
|
|-- references/
|   |-- workflow.md
|   |   `-- Progressive memory workflow guidance for root memory, detail pages, and compression checkpoints.
|   |
|   |-- tiering.md
|   |   `-- Usage counting, safety pinning, and root/index/detail/archive recommendation rules.
|   |
|   |-- splitting.md
|   |   `-- Concrete-topic split boundaries, optional Luna plans, and post-split validation.
|   |
|   `-- llm_tradeoffs.md
|       `-- Division-of-labor guidance for what scripts should handle and what the LLM should judge.
|
|-- scripts/
|   `-- run_memory_steward.ps1
|       `-- PowerShell scanner that reports, touches, ranks, and identifies oversized memory.
|
`-- tests/
    `-- run_tests.ps1
        `-- Dependency-free regression tests for counters, concurrency, encoding, tiers, and size boundaries.
```

## Quick Start

```powershell
# Compact, read-only report
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project

# Record a memory entry that was actually used
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project -TouchId agent.area.topic -Quiet

# Full inventory for precise filtering or automation
./scripts/run_memory_steward.ps1 -RepoRoot C:\path\to\project -OutputFormat Json

# Run the dependency-free regression suite
./tests/run_tests.ps1
```

The scanner never moves or deletes memory. Touch updates one ID at a time with a repository lock, strict UTF-8 validation, and atomic replacement. It reports tier changes and oversized files; Codex or an optional Luna planner performs semantic splitting only after local secret filtering and diff review. New memory follows the user's/project's language, with concise Simplified Chinese preferred for Chinese workflows.

## Method Flow

```text
Scan project memory
        |
        v
Collect verifiable facts
        |
        v
Classify stable lessons vs. noise
        |
        v
Update root and detailed memory docs
        |
        v
Validate markers and memory size
        |
        v
Use results before future compression
```
