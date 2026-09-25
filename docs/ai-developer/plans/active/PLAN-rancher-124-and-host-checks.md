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

## Status: Active

**Terje's answers (urb-agents #1519, 2026-09-25):** Q1 yes, Q2 yes, Q3 yes, Q4 drop.

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

## Phase 1: Windows: Rancher Desktop 1.22.0 → 1.24.0 (part a) — DONE, validated in CI

### Tasks

- [x] 1.1 `scripts-win/rancher-desktop/install.ps1:39`: `$RANCHER_VERSION = "1.24.0"`. The asset name is unchanged in the 1.24.0 release (`Rancher.Desktop.Setup.1.24.0.msi`, checked 2026-09-25)
- [x] 1.2 `install.ps1:69`: `$PROFILE_VERSION` 17 → **19**, matching `CURRENT_SETTINGS_VERSION` in Rancher v1.24.0 (`pkg/rancher-desktop/config/settings.ts:9`). An older number would still be migrated, but the right number avoids depending on that
- [x] 1.3 *(Q3 = yes)*: download `<msi>.sha512sum` beside the MSI, compare it with `Get-FileHash -Algorithm SHA512`, and stop before `msiexec` on a mismatch, with a new `ERRnnn` and a plain sentence
- [x] 1.4 Update `scripts-win/rancher-desktop/README.md` (version, and the hash check if added). Leave the example test logs as 1.22.0 history
- [x] 1.5 MINOR version bump: `bash docs/ai-developer/tools/set-version-powershell.sh rancher-desktop`

### Validation

`bash docs/ai-developer/tools/validate-powershell.sh rancher-desktop` passes.

**Result so far:** not run. There is no `pwsh` on tecMacDev. Checked by other means:
- The file is pure ASCII (PowerShell 5.1 requirement).
- The real `Rancher.Desktop.Setup.1.24.0.msi.sha512sum` has the format `<hash> *<file>`, which the parser handles. It is served as `application/octet-stream`, and the byte[] case is handled.
- `SCRIPT_VER` was bumped to 0.3.0 by hand (the same regex as `set-version-powershell.sh`, whose GNU `sed -i` misbehaves on macOS).

**Must pass in the devcontainer or CI before merge.**

**Found while implementing — needs Terje:**
- `detect.ps1` does not check the version, and `install.ps1`'s already-installed branch does not upgrade. So **the 1.24.0 pin only affects new installs**, and PCs already on 1.22.0 stay there.
- The already-installed branch also **deletes the user's `settings.json`** so that the profile applies. On a re-run, that would wipe a UIS user's own Kubernetes and resource settings.

Both are existing behaviour, not changed here. **This needs `pwsh`, which is not on tecMacDev**, so run it in the devcontainer, or let CI run it (the pipeline validates `scripts-win/` on push to `main`).

---

## Phase 2: Windows: Windows 11 + x64 check (part b) — DONE, validated in CI

### Tasks

- [x] 2.1 `scripts-win/wsl2/install.ps1:41`: `$MIN_BUILD` 19041 → **22000** (Windows 11). Change the ERR002 text to plain words: "This PC runs Windows build <n>. Windows 11 is required."
- [x] 2.2 Add an x64 check next to it (`$env:PROCESSOR_ARCHITECTURE` = `AMD64`, and `PROCESSOR_ARCHITEW6432` for a 32-bit host). The error says: "This PC has an ARM processor. Only x64 PCs are supported."
- [x] 2.3 The same two checks at the start of `scripts-win/rancher-desktop/install.ps1`, because Rancher 1.24 needs Windows 11 and its installer is x64-only. Each script must stand on its own in Intune
- [x] 2.4 Update `detect.ps1` only if it depends on the build number (check first). Update the READMEs
- [x] 2.5 MINOR bump: `set-version-powershell.sh wsl2`

### Validation

The validators pass as in Phase 1. On Terje's PC (Windows 11, x64) both checks must **pass**. The failure paths are exercised only by a unit-style test that mocks the build and arch values (see 2.6).

- [x] 2.6 Add a test in `scripts-win/wsl2/tests/` for the check logic, runnable in the devcontainer with `pwsh`. It is `test-platform-check.ps1`: it reads `Test-HostPlatform` out of **both** install scripts by AST (without running them) and checks 5 build/arch cases

**Notes from Phase 2:**
- **Architecture comes from `Win32_Processor.Architecture`**, with the environment variable as fallback. An x64 PowerShell under emulation on an ARM64 PC reports `PROCESSOR_ARCHITECTURE=AMD64`, so the variable alone could miss ARM. **Untested on an ARM PC.**
- **Error codes:** wsl2 ERR002 (build, reused) and **ERR008** (arch; ERR004 was already unused before this change). rancher-desktop **ERR010** / **ERR011**.
- **Also updated:** `INTUNE.md` (both packages, minimum OS → Windows 11 21H2, x64 only), `wsl2/TESTING.md` and `tests/test-0-prerequisites.ps1` (build 22000), so the USB test agrees with the script. SCRIPT_VER for wsl2 is 0.3.0.
- **`detect.ps1` (wsl2)** doesn't use the build number, so it is unchanged.

---

## Phase 3: Mac: Rancher scripts to legacy, Jamf profile in the repo (Q1, Q2) — DONE

### Tasks

- [x] 3.1 `git mv scripts-mac/rancher-desktop scripts-mac/legacy/rancher-desktop`. Add `scripts-mac/legacy/README.md`: "Replaced on 2026-09-25 by Jamf's native Rancher Desktop install with a deployment profile; kept for reference"
- [x] 3.2 Add `scripts-mac/rancher-desktop-jamf/io.rancherdesktop.profile.defaults.plist` (the file Terje gave the Jamf manager, verbatim) and a README: the preference domain, where macOS puts the file, and the "defaults apply only on first launch" caveat. Include the source-code lines checked in #1516
- [x] 3.3 Fix references (`docs/OPS.md`, `docs/README.md`, `docs/SCRIPT-STANDARDS.md`, `docs/AI-EXAMPLE-WORKFLOW.md`, `scripts-win/rancher-desktop/README.md`, `scripts-mac/devcontainer-toolbox/TESTING.md`), and the package table in `project-client-provisioning.md`
- [x] 3.4 Make sure `validate-bash.sh` still runs: either it skips `legacy/`, or the moved scripts still pass. Decide, and say which

### Validation

`validate-bash.sh` exits 0, and the link check reports 0 broken links outside `plans/completed/`.

**Results:**
- `validate-bash.sh`: 3/3 pass. **3.4 decision: the default run skips `legacy/`**, because it only checks `.sh` at a package's top level. `validate-bash.sh legacy/rancher-desktop` still passes 4/4.
- Link check: 0 broken.
- The move is 22 renames (100 %), so history is kept.
- `devcontainer-toolbox/tests/test-0-prerequisites.sh`: only its "install Rancher" hint changed (now points to Jamf / rancherdesktop.io). PATCH 0.2.1.

**Found, not fixed (outside this plan):** `validate-bash.sh devcontainer-toolbox/tests` fails **8 of 9** on the `startup` check (`log_info "Starting: ..."` missing). It fails the same on `main` without this change.

**Left as history:** `docs/AI-EXAMPLE-WORKFLOW.md:62` (an example transcript) and the author's text in `INVESTIGATE-windows-one-script-install.md:96`.

---

## Phase 1b: Upgrade existing PCs (Terje: option A, urb-agents #1522) — DONE, CI green (run 36123809935: validator 13/13, platform 10/10, version pin OK)

- [x] 1b.1 `detect.ps1`: an installed version below `$MIN_RANCHER_VERSION` (1.24.0) = **not detected**, so Intune runs install. **Version unreadable = detected**, to avoid a reinstall loop
- [x] 1b.2 `install.ps1`, already-installed branch: if the version is older than the pin, stop Rancher, check internet and disk, then download → **SHA512 check** → `msiexec` over the top. Then verify as before
- [x] 1b.3 **Removed the `settings.json` deletion** in the already-installed branch, so user choices survive re-runs and upgrades. The deletion **in the fresh-install branch is kept**: when Rancher isn't installed, leftover settings from an old uninstall are stale
- [x] 1b.4 `tests/test-version-pin.ps1` fails if `detect.ps1` and `install.ps1` pin different versions. It is in CI

**Untested, and to check on Terje's PC:**
- **Where the version comes from:** the exe's `ProductVersion`, then `FileVersion`. I haven't seen what Rancher's Electron build puts there. The test log will show it.
- **The MSI upgrade over an existing per-user install:** not tried anywhere. His PC is already on 1.24.0, so it takes the no-upgrade path.

## CI result (PR #18, run 36121710567, 2026-09-25)

- **`validate-powershell.sh`:** 13/13, with PSScriptAnalyzer found.
- **`test-platform-check.ps1`:** 5/5 cases against each of the two installers (10/10).
- **`intunewin`:** all 3 packages build. The rancher-desktop build test unpacks the package and checks its files. wsl2 has no build test.
- **0 artifacts uploaded.**
- **Not covered:** the validator checks only top-level package scripts, so `tests/*.ps1` (including the new test) is not linted.

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
