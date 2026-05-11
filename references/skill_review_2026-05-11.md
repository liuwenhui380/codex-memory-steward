# Skill Review Log - 2026-05-11

## Scope

Reviewed `codex-memory-steward` as a reusable Codex skill package: trigger policy, README consistency, release notes, PowerShell scanner behavior, local memory hygiene, and release packaging.

## Findings

1. Trigger policy had been too broad in earlier versions.
   - Fix already present on this branch: `SKILL.md` now separates trigger and non-trigger signals, adds decision priority, and defines an output contract.

2. README files needed to mirror the skill policy.
   - Fix already present on this branch: English and Chinese READMEs now include trigger/non-trigger rules, migration SOP, and output contract.

3. Release history was implicit.
   - Fix already present on this branch: `RELEASE_NOTES.md` records `v1.1.0` and `v1.1.1` changes.

4. `run_memory_steward.ps1` produced mojibake in `project_inventory.md` for UTF-8 files such as `README-ZH.md`.
   - Fix: `Get-FileSummary` now reads text with explicit UTF-8 encoding.

5. `run_memory_steward.ps1 -Apply` could inventory files intentionally hidden by `.gitignore`, including this repo's local `agent.md`.
   - Fix: `Get-ProjectFiles` now skips gitignored paths when the target root is a Git worktree.

## Validation

- Ran `scripts/run_memory_steward.ps1 -RepoRoot . -Apply`.
- Confirmed generated inventory no longer includes ignored `agent.md`.
- Confirmed `README-ZH.md` summary renders as Chinese instead of mojibake.
- Ran `git diff --check`.
- Scanned changed docs/scripts for secret-like tokens.

## Remaining Notes

- The helper script is still PowerShell-first. Cross-platform wrappers remain a future enhancement.
- Local memory files under `agent.md` and `.agent/` stay intentionally ignored in this repository.
