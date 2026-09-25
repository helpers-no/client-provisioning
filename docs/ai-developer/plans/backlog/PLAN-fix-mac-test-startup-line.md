# Plan: Fix the 8/9 startup-line failures in scripts-mac/devcontainer-toolbox/tests

Make the Mac devcontainer-toolbox test scripts follow the script standard, so their folder can be part of CI.

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) — The implementation process
> - [PLANS.md](../../PLANS.md) — Plan structure and best practices
> - [rules/script-standard.md](../../rules/script-standard.md) — Shared script standard
> - [rules/bash.md](../../rules/bash.md) — Bash-specific rules
>
> **UPDATE THIS PLAN AS YOU WORK:** Mark tasks `[x]` when done, add `— DONE` to phase headers, update status.

## Status: Backlog. Changes files under `scripts-mac/`, so it needs an ask before implementing

**Found:** 2026-09-25, while working on PLAN-rancher-124-and-host-checks. Confirmed independently by ops-dev (urb-agents #1523):

```
validate-bash.sh devcontainer-toolbox/tests   9 scripts, 1 passed, 8 failed   (same on main)
```

**Cause:** the test scripts define their own `log_*` functions but not `log_start`, and never print the standard line `log_info "Starting: $SCRIPT_NAME Ver: $SCRIPT_VER"`, which `validate-bash.sh` check 4 (startup) requires. Only `test-helpers.sh` has it.

**Why it matters now:** CI (PLAN-github-actions-ci) is becoming the gate. A folder that has failed 8/9 for long enough that nobody mentions it hides the next real failure.

## Phase 1: Fix

- [ ] 1.1 In each failing script (`run-all-tests.sh`, `test-0` … `test-6`), add `log_start() { log_info "Starting: $SCRIPT_NAME Ver: $SCRIPT_VER"; }` next to the other `log_*` functions, and call `log_start` at the top of main. **Output change only:** one extra log line; the test logic is untouched
- [ ] 1.2 PATCH-bump `SCRIPT_VER` in each changed script
- [ ] 1.3 Check the other test folders the same way (`validate-bash.sh <pkg>/tests` for every package, including `legacy/`), and list what else fails

## Validation

`bash docs/ai-developer/tools/validate-bash.sh devcontainer-toolbox/tests` → 9/9 pass. Then add the folder to CI (PLAN-github-actions-ci task 1.5).

## Files to Modify

- `scripts-mac/devcontainer-toolbox/tests/*.sh` (8 files)
