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

## Status: Backlog

**Why it's first:** tecMacDev has no `pwsh`, `docker`, `podman` or `dotnet`, and ops-dev runs on the same host. **Until CI exists, PowerShell changes either merge unvalidated or don't merge.** This plan gates [PLAN-rancher-124-and-host-checks](../active/PLAN-rancher-124-and-host-checks.md) (PR #18).

**Last Updated:** 2026-09-25

---

## Decisions already made

- **4a yes, 4b later** (Terje, #1520): CI builds and tests. **Nothing is published.**
- **The Azure pipeline stays** (Terje didn't answer on retiring it).
- ⚠️ **Correction to what I told Terje on #1520:** I called PR workflow artifacts "private to the repo's viewers". **In a public repo, any signed-in GitHub user can download them.** So this plan **does not upload `.intunewin` files as artifacts.** CI builds them, tests them, and discards them. Uploading anything installable is 4b, which is a separate decision.

## Phase 1: Validation workflow

### Tasks

- [ ] 1.1 `.github/workflows/validate.yml`, on `pull_request` and on `push` to `main`, with `permissions: contents: read` only
- [ ] 1.2 Job `bash` (ubuntu-latest): `bash docs/ai-developer/tools/validate-bash.sh`, the same command as locally. shellcheck is preinstalled on the runner
- [ ] 1.3 Job `powershell` (ubuntu-latest, where `pwsh` is preinstalled): install PSScriptAnalyzer, then `bash docs/ai-developer/tools/validate-powershell.sh`. The tool must be what defines "validated", not a copy of its checks
- [ ] 1.4 Job `powershell` also runs `pwsh scripts-win/wsl2/tests/test-platform-check.ps1`
- [ ] 1.5 **Test folders:** `devcontainer-toolbox/tests` fails 8/9 today, and fails the same on `main`. It is **not** added to CI until [PLAN-fix-mac-test-startup-line](PLAN-fix-mac-test-startup-line.md) lands; then it is added, so CI can be green and still honest
- [ ] 1.6 Pin actions to a full commit SHA, not a tag

### Validation

The workflow runs on this plan's own PR. **It will run the PowerShell validator for the first time ever on this repo's scripts.** Any failure it finds on `main` is recorded and fixed, or filed; it is not suppressed.

## Phase 2: Build and test the .intunewin (not uploaded)

### Tasks

- [ ] 2.1 Job `intunewin` (ubuntu-latest), a matrix over the packages that have `build.ps1`: install `SvRooij.ContentPrep.Cmdlet`, run `build.ps1`, then run `tests/run-tests-build.ps1` if it exists. These are the same steps as `.azure-pipelines/build-intunewin.yml`
- [ ] 2.2 **To verify:** that `SvRooij.ContentPrep.Cmdlet` packs correctly on Linux. The Azure job runs on its default agent, and I haven't checked which OS that is. If it fails on Linux, use `windows-latest` for this job
- [ ] 2.3 No `upload-artifact` step. Add a comment in the workflow saying why (public repo, 4b not approved)

## Phase 3: Make it the gate

- [ ] 3.1 Ask Terje/ops-dev to set **branch protection on `main`**: the `bash`, `powershell` and `intunewin` checks are required. That's a repo setting, outward-facing, so it needs an ask
- [ ] 3.2 Update `project-client-provisioning.md` → Commands: "CI is the validator of record for PowerShell"

## Acceptance Criteria

- [ ] A PR shows the three jobs. On this plan's PR, `bash` and `powershell` run to completion (pass, or real failures recorded)
- [ ] PR #18 (rancher-124) gets a real PowerShell result
- [ ] No installable file is uploaded anywhere

## Files to Modify

- New `.github/workflows/validate.yml`
- `docs/ai-developer/project-client-provisioning.md`
