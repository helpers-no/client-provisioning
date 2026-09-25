# Plan: Rancher Desktop 1.24 on Windows, Windows 11 check, Mac Rancher scripts to legacy

Bring the Windows packages up to devcontainer-toolbox's host requirements, and retire our Mac Rancher Desktop scripts now that Jamf installs Rancher natively.

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) — The implementation process
> - [PLANS.md](../../PLANS.md) — Plan structure and best practices
> - [rules/script-standard.md](../../rules/script-standard.md) — Shared script standard
> - [rules/powershell.md](../../rules/powershell.md) — PowerShell-specific rules
> - [rules/bash.md](../../rules/bash.md) — Bash-specific rules
>
> **UPDATE THIS PLAN AS YOU WORK:** Mark tasks `[x]` when done, add `— DONE` to phase headers, update status.

## Status: Backlog — waiting for Terje's review

**Source:** urb-agents #1510 (Terje: "a yes, b yes"), #1516 (Jamf profile, "move our old setup to legacy"), #1505 / #1514 (DCT host requirements).

**⚠️ Consequence:** everything this plan changes under `scripts-win/` ships as an `.intunewin` package. It **runs with administrator rights on managed PCs belonging to real people.** Nothing reaches Intune until the manual test on Terje's managed PC has passed and he has seen the result.

**Last Updated:** 2026-09-25

---

## Questions for Terje (answer on the review item)

| # | Question | My proposal |
|---|---|---|
| **Q1** | **What moves to legacy on the Mac?** Jamf now installs Rancher Desktop with the defaults profile (#1516) | Move `scripts-mac/rancher-desktop/` **as a whole** to `scripts-mac/legacy/rancher-desktop/`, including install, config, k8s, uninstall and tests. The config and k8s scripts write the same `/Library/Managed Preferences` files that Jamf now manages, so keeping them live would fight Jamf |
| **Q2** | **Where does the Jamf profile live?** | `scripts-mac/rancher-desktop-jamf/io.rancherdesktop.profile.defaults.plist` plus a short README. It is the file you gave the Jamf manager, so the repo keeps the source of truth |
| **Q3** | **Add hash verification to the Windows MSI download?** Rancher publishes `Rancher.Desktop.Setup.1.24.0.msi.sha512sum`; today we don't check it | **Yes.** The installer runs elevated, so a download that can't be verified should stop the install. This goes beyond the "pin bump" you approved, so it needs its own yes |
| **Q4** | **Part d** (Apple Silicon + macOS 13 check): still wanted? | If Q1 is yes, it only remains for `scripts-mac/devcontainer-toolbox/`. **I'd drop it** until the one-script Mac installer exists, where DCT's `install.sh` makes the same check (#1514) |

---

## Phase 1: Windows: Rancher Desktop 1.22.0 → 1.24.0 (part a)

### Tasks

- [ ] 1.1 `scripts-win/rancher-desktop/install.ps1:39`: `$RANCHER_VERSION = "1.24.0"`. The asset name is unchanged in the 1.24.0 release (`Rancher.Desktop.Setup.1.24.0.msi`, checked 2026-09-25)
- [ ] 1.2 `install.ps1:69`: `$PROFILE_VERSION` 17 → **19**, matching `CURRENT_SETTINGS_VERSION` in Rancher v1.24.0 (`pkg/rancher-desktop/config/settings.ts:9`). An older number would still be migrated, but the right number avoids depending on that
- [ ] 1.3 *(only if Q3 = yes)*: download `<msi>.sha512sum` beside the MSI, compare it with `Get-FileHash -Algorithm SHA512`, and stop before `msiexec` on a mismatch, with a new `ERRnnn` and a plain sentence
- [ ] 1.4 Update `scripts-win/rancher-desktop/README.md` (version, and the hash check if added). Leave the example test logs as 1.22.0 history
- [ ] 1.5 MINOR version bump: `bash docs/ai-developer/tools/set-version-powershell.sh rancher-desktop`

### Validation

`bash docs/ai-developer/tools/validate-powershell.sh rancher-desktop` passes. **This needs `pwsh`, which is not on tecMacDev**, so run it in the devcontainer, or let CI run it (the pipeline validates `scripts-win/` on push to `main`).

---

## Phase 2: Windows: Windows 11 + x64 check (part b)

### Tasks

- [ ] 2.1 `scripts-win/wsl2/install.ps1:41`: `$MIN_BUILD` 19041 → **22000** (Windows 11). Change the ERR002 text to plain words: "This PC runs Windows build <n>. Windows 11 is required."
- [ ] 2.2 Add an x64 check next to it (`$env:PROCESSOR_ARCHITECTURE` = `AMD64`, and `PROCESSOR_ARCHITEW6432` for a 32-bit host). The error says: "This PC has an ARM processor. Only x64 PCs are supported."
- [ ] 2.3 The same two checks at the start of `scripts-win/rancher-desktop/install.ps1`, because Rancher 1.24 needs Windows 11 and its installer is x64-only. Each script must stand on its own in Intune
- [ ] 2.4 Update `detect.ps1` only if it depends on the build number (check first). Update the READMEs
- [ ] 2.5 MINOR bump: `set-version-powershell.sh wsl2`

### Validation

The validators pass as in Phase 1. On Terje's PC (Windows 11, x64) both checks must **pass**. The failure paths are exercised only by a unit-style test that mocks the build and arch values (see 2.6).

- [ ] 2.6 Add a test in `scripts-win/wsl2/tests/` for the check logic, runnable in the devcontainer with `pwsh`

---

## Phase 3: Mac: Rancher scripts to legacy, Jamf profile in the repo (Q1, Q2)

### Tasks

- [ ] 3.1 `git mv scripts-mac/rancher-desktop scripts-mac/legacy/rancher-desktop`. Add `scripts-mac/legacy/README.md`: "Replaced on 2026-09-25 by Jamf's native Rancher Desktop install with a deployment profile; kept for reference"
- [ ] 3.2 Add `scripts-mac/rancher-desktop-jamf/io.rancherdesktop.profile.defaults.plist` (the file Terje gave the Jamf manager, verbatim) and a README: the preference domain, where macOS puts the file, and the "defaults apply only on first launch" caveat. Include the source-code lines checked in #1516
- [ ] 3.3 Fix references (`docs/OPS.md`, `docs/README.md`, `docs/SCRIPT-STANDARDS.md`, `docs/AI-EXAMPLE-WORKFLOW.md`, `scripts-win/rancher-desktop/README.md`, `scripts-mac/devcontainer-toolbox/TESTING.md`), and the package table in `project-client-provisioning.md`
- [ ] 3.4 Make sure `validate-bash.sh` still runs: either it skips `legacy/`, or the moved scripts still pass. Decide, and say which

### Validation

`validate-bash.sh` exits 0, and the link check reports 0 broken links outside `plans/completed/`.

---

## Phase 4: Test on real machines, then ship

### Tasks

- [ ] 4.1 **Terje's managed Windows PC** (not clean: Rancher 1.24.0 and WSL already there). Run `wsl2/install.ps1` (must pass its checks and detect the existing features) and `rancher-desktop/install.ps1` (must detect 1.24.0 and not reinstall it, or reinstall cleanly; record which). Follow the steps in `scripts-win/*/TESTING.md`. **This is a person at the keyboard, not me.**
- [ ] 4.2 **tecMacWork**: nothing to run from this repo after Phase 3. The Jamf profile is tested by the Jamf manager on a Mac where Rancher has **not** been started yet. That Mac isn't available, so this stays **untested**
- [ ] 4.3 Ask on the bus before push, PR, merge, and building/uploading the `.intunewin`

---

## Acceptance Criteria

**Checkable here (tecMacDev / devcontainer):**
- [ ] Both validators pass (PowerShell in the devcontainer or CI)
- [ ] 0 broken relative links
- [ ] SCRIPT_VER bumped (MINOR) in `rancher-desktop` and `wsl2`

**Only on a real machine (Terje):**
- [ ] On his managed Windows 11 PC, both installers run, pass their checks, and leave Rancher 1.24.0 working (`docker run hello-world`)
- [ ] A clean-install run: **not possible on this PC.** It stays untested until a clean machine exists
- [ ] The Jamf profile applies on a never-launched Mac: **untested**, no machine available

## Files to Modify

- `scripts-win/rancher-desktop/install.ps1`, `README.md`
- `scripts-win/wsl2/install.ps1`, `README.md`, possibly `detect.ps1`, and new `tests/` file
- `scripts-mac/rancher-desktop/` → `scripts-mac/legacy/rancher-desktop/` (moved), new `scripts-mac/legacy/README.md`
- New `scripts-mac/rancher-desktop-jamf/` (profile + README)
- References in `docs/` and `project-client-provisioning.md`
