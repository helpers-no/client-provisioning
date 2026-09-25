# Plan: GitHub Actions CI: validate bash and PowerShell, build and test the .intunewin (no publishing)

Make CI the gate for every PR, because no host in the fleet can run `pwsh` (step 4a, approved by Terje on urb-agents #1520; endorsed by ops-dev on #1523).

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) — The implementation process
> - [PLANS.md](../../PLANS.md) — Plan structure and best practices
> - [rules/script-standard.md](../../rules/script-standard.md) — Shared script standard
> - [rules/powershell.md](../../rules/powershell.md) — PowerShell-specific rules
> - [rules/bash.md](../../rules/bash.md) — Bash-specific rules
>
> **UPDATE THIS PLAN AS YOU WORK:** Mark tasks `[x]` when done, add `— DONE` to phase headers, update status.

## Status: Active: **live on `main` since PR #20 (2026-09-25)**. Open: 1.5 (test folders) and 3.1 (branch protection, #1528)

**Why it's first:** tecMacDev has no `pwsh`, `docker`, `podman` or `dotnet`, and ops-dev runs on the same host. **Until CI exists, PowerShell changes either merge unvalidated or don't merge.** This plan gates [PLAN-rancher-124-and-host-checks](../active/PLAN-rancher-124-and-host-checks.md) (PR #18).

**Last Updated:** 2026-09-25

---

## Decisions already made

- **4a yes, 4b later** (Terje, #1520): CI builds and tests. **Nothing is published.**
- **The Azure pipeline stays** (Terje didn't answer on retiring it).
- ⚠️ **Correction to what I told Terje on #1520:** I called PR workflow artifacts "private to the repo's viewers". **In a public repo, any signed-in GitHub user can download them.** So this plan **does not upload `.intunewin` files as artifacts.** CI builds them, tests them, and discards them. Uploading anything installable is 4b, which is a separate decision.

## Phase 1: Validation workflow

### Tasks

- [x] 1.1 `.github/workflows/validate.yml`, on `pull_request` and on `push` to `main`, with `permissions: contents: read` only
- [x] 1.2 Job `bash` (ubuntu-latest): `bash docs/ai-developer/tools/validate-bash.sh`, the same command as locally. shellcheck is preinstalled on the runner
- [x] 1.3 Job `powershell` (ubuntu-latest, where `pwsh` is preinstalled): install PSScriptAnalyzer, then `bash docs/ai-developer/tools/validate-powershell.sh`. The tool must be what defines "validated", not a copy of its checks
- [x] 1.4 Job `powershell` also runs `pwsh scripts-win/wsl2/tests/test-platform-check.ps1`. **Moved to PR #18**, because the test file exists only there. The first run failed on this step because the file doesn't exist on `main`. The step now lands with the test, and on PR #18 it passes 10/10
- [ ] 1.5 **Test folders** (bash **and** PowerShell: the validator lints only top-level package scripts, so `scripts-win/*/tests/*.ps1` is not linted either; check what fails before adding it): `devcontainer-toolbox/tests` fails 8/9 today, and fails the same on `main`. It is **not** added to CI until [PLAN-fix-mac-test-startup-line](PLAN-fix-mac-test-startup-line.md) lands; then it is added, so CI can be green and still honest
- [x] 1.6 Pin actions to a full commit SHA, not a tag

### Validation

The workflow runs on this plan's own PR. **It will run the PowerShell validator for the first time ever on this repo's scripts.** Any failure it finds on `main` is recorded and fixed, or filed; it is not suppressed.

## Phase 2: Build and test the .intunewin (not uploaded)

### Tasks

- [x] 2.1 Job `intunewin` (ubuntu-latest), a matrix over the packages that have `build.ps1`: install `SvRooij.ContentPrep.Cmdlet`, run `build.ps1`, then run `tests/run-tests-build.ps1` if it exists. These are the same steps as `.azure-pipelines/build-intunewin.yml`
- [x] 2.2 **Resolved:** `azure-pipelines.yml` uses `pool: vmImage: 'ubuntu-latest'`, so ContentPrep already packs on Linux in Azure. The GitHub job uses `ubuntu-latest` too
- [x] 2.3 No `upload-artifact` step. Add a comment in the workflow saying why (public repo, 4b not approved)

## Phase 3: Make it the gate

- [x] 3.1 *(asked: urb-agents #1528)* Ask Terje/ops-dev to set **branch protection on `main`**: the `bash`, `powershell` and `intunewin` checks are required. That's a repo setting, outward-facing, so it needs an ask
- [x] 3.2 Update `project-client-provisioning.md` → Commands: "CI is the validator of record for PowerShell"

## Notes from implementing

- **First run (PR #20, run 36121363155):**
  - `bash`: pass.
  - `powershell`: **`validate-powershell.sh` passed 13/13 with PSScriptAnalyzer found.** That is the first pre-merge PowerShell validation of `main`. The job then failed on the unit-test step, because the test file isn't on `main` (my wiring error). Fixed by moving the step to PR #18, not by skipping it.
  - `intunewin`: skipped, because it depends on `powershell`.

- **Azure already runs `validate-powershell.sh`, but only after a push to `main`** (Validate stage, `azure-pipelines.yml`). PowerShell validation existed, just never **before** merge. This workflow moves it onto the PR.
- **`validate-powershell.sh` skips PSScriptAnalyzer silently** when the module is missing, so the workflow installs it first. Otherwise "pass" would mean less than it says.
- `actions/checkout` is pinned to `3d3c42e5aac5ba805825da76410c181273ba90b1` (v7.0.1, resolved 2026-09-25).
- The YAML parses (checked with Ruby's YAML). It has **not run yet**, because GitHub runs it only once it's pushed.
- The packages with `build.ps1` are rancher-desktop, wsl2 and devcontainer-toolbox. wsl2 has no `run-tests-build.ps1`, so that step is skipped for it.

## Acceptance Criteria

- [ ] A PR shows the three jobs. On this plan's PR, `bash` and `powershell` run to completion (pass, or real failures recorded)
- [ ] PR #18 (rancher-124) gets a real PowerShell result
- [ ] No installable file is uploaded anywhere

## Files to Modify

- New `.github/workflows/validate.yml`
- `docs/ai-developer/project-client-provisioning.md`
