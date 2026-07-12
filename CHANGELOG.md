# Changelog

## Unreleased

### Added
- Explicit `-TouchId` usage counting with `-Quiet` minimal-context mode.
- Frequency/recency/pinning-based root, index, detail, and archive recommendations.
- Oversized-memory detection with 80-line route targets and 120-line/12 KiB detail thresholds.
- Concrete-topic splitting guidance and optional Luna JSON planning contract.
- Dependency-free PowerShell regression suite covering concurrency, encoding, inventory, tiers, and size boundaries.

### Changed
- Compact Markdown is now the default report; full inventories remain available through JSON.
- `-Apply` generated project memory and inventory text now defaults to Simplified Chinese while preserving technical identifiers.

### Safety
- Touch updates one ID at a time under a normalized repository lock.
- Strict UTF-8 validation, concurrent-change hashing, and same-directory atomic replacement prevent count loss and encoding damage.

## v1.1.3 - 2026-05-11

### Changed
- Renamed tracked version history from `RELEASE_NOTES.md` to `CHANGELOG.md`.
- Kept tracked `references/` focused on runtime reference files used by the skill.
- Moved process review logs into local `.agent/` project memory instead of shipping them as runtime references.

## v1.1.2 - 2026-05-11

### Added
- Added an auditable skill review and fix log for the scanner reliability pass.

### Fixed
- `run_memory_steward.ps1` now reads text summaries with explicit UTF-8 encoding, fixing mojibake in generated inventories for files such as `README-ZH.md`.
- `run_memory_steward.ps1 -Apply` now skips gitignored files when building `.agent/project_inventory.md`, so local-only memory such as `agent.md` is not listed as project source content.

### Compatibility
- Backward-compatible script behavior. Non-Git folders still scan normally; Git worktrees get additional ignore-aware filtering.

## v1.1.1 - 2026-05-11

### Added
- Synced `README.md` with new skill policy sections: trigger/non-trigger, decision priority, migration SOP, and output contract.
- Synced `README-ZH.md` with equivalent Chinese guidance for the same policy sections.

### Changed
- Clarified repository layout docs to include release artifacts and versioned metadata context.

### Compatibility
- Documentation-only release; no script/runtime behavior changes.

## v1.1.0 - 2026-05-11

### Added
- Trigger and non-trigger sections to reduce accidental invocation.
- Explicit decision-priority policy for instruction conflicts.
- Migration SOP for consolidating usage-stat display to one Markdown layer.
- Validation checklist now includes direct repair actions.
- Output contract for consistent downstream consumption.

### Changed
- `agent.md` 200-line rule is now a soft target with explicit overflow handling guidance.
- Skill metadata description narrowed to high-confidence memory-stewardship scenarios.

### Compatibility
- No script/runtime behavior changes; this release updates skill policy and operational guidance only.
