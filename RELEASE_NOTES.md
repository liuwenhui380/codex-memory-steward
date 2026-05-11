# Release Notes

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
