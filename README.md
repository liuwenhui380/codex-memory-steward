# Codex Memory Steward

Codex Memory Steward is a memory-management method and reusable Codex skill for long-running Codex projects. It turns stable, reusable lessons from development sessions into structured project memory.

The goal is not to save chat history. The goal is to preserve project knowledge that can shape future decisions across multi-step development, context compression, and cross-session collaboration.

## Core Principle

The method separates project-memory stewardship into two complementary stages:

1. Deterministic scanning

   Scripts collect verifiable facts first, such as project-root `agent.md` line counts, project-local `.agent/` detail pages, `AGENTS.md`, `README.md`, usage markers, and recent session-record locations. This gives the LLM stable input instead of relying on memory or impression.

2. Semantic judgment and compression

   The LLM reviews the scan output and decides which findings are durable lessons and which are one-off debugging noise. Stable lessons are compressed into concise entries and placed in the root memory file or detailed memory pages.

3. Progressive disclosure

   The project-root `agent.md` stays short and navigation-focused. Detailed operational knowledge lives in project-local `.agent/*.md`, so future agents can read the most important constraints first and expand into details only when needed.

4. Usage-feedback markers

   Usage markers record `count`, `since`, and `last` metadata for memory entries. Frequently or recently used memories are preserved first, while low-use entries can be compressed or demoted after review.

## Key Features

- Script and LLM division of labor: scripts collect facts, while the LLM handles semantic filtering and concise rewriting.
- Compression-aware workflow: stable lessons are captured before long-session context compression.
- Low-noise memory: the method favors rules that change future behavior instead of storing complete session history.
- Layered memory structure: a short root file points to hidden detail pages for deeper project knowledge.
- Usage-marker mechanism: frequency and recency become practical signals for memory compression.
- Portable skill package: the approach is not tied to one project and can be reused across Codex repositories.

## Memory Location

Place `agent.md` in the target project's root folder. Place detailed memory pages under that same project's `.agent/` directory. Do not store project memory under `~/.codex`; that directory is only scanned for Codex session records.

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
|   `-- llm_tradeoffs.md
|       `-- Division-of-labor guidance for what scripts should handle and what the LLM should judge.
|
`-- scripts/
    `-- run_memory_steward.ps1
        `-- PowerShell scanner that generates a project-memory status report and usage-marker summary.
```

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
