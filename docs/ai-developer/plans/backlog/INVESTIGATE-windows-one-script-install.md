# Investigate: One-Script Install for Non-Developers (Windows first, managed PCs and Macs)

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

> **Moved here from devcontainer-toolbox (2026-09-25).** Terje decided the split: **client-provisioning owns "the machine is ready"** (WSL, Rancher Desktop, VS Code + Dev Containers extension, elevation, restart/resume, Intune/Jamf packages). **devcontainer-toolbox owns "the project is ready"** (`devcontainer.json`, the image, everything inside the container). The user still sees **one command** on the DCT website: this repo's installer prepares the machine and, as its last step, runs DCT's own `install.ps1` / `install.sh`. DCT's side of the contract (its host requirements and the handover message) is [PLAN-host-installer-handover](https://github.com/helpers-no/devcontainer-toolbox/blob/main/website/docs/ai-developer/plans/backlog/PLAN-host-installer-handover.md) in devcontainer-toolbox. Adjust the `IMPLEMENTATION RULES` links to this repo's `docs/ai-developer/` paths when landing the file.

> **Landed in client-provisioning on 2026-09-25** from the comment on urb-agents #1492, as written
> by devcontainer-toolbox. The only edit to the author's text is the IMPLEMENTATION RULES links.
> This section was added on landing. **In the body, "this repo" and `install.ps1` / `install.sh`
> mean devcontainer-toolbox**, where the file was written.
> Related here: [INVESTIGATE-wsl-intune.md](INVESTIGATE-wsl-intune.md) covers the Intune
> SYSTEM-context WSL problem. That is this file's Option C fallback, not its main path.

## ⚠️ Untested claims — read before relying on anything below

**Nobody has run the one-script flow on any machine.** No managed Windows 11 PC (Intune) and no
Jamf Mac has been used to test anything in this file. Only Terje can arrange those machines, so this
gap will persist. Every claim below is one of:

- **Vendor-documented**: read in vendor docs, manifests, code or issues. Not run by us.
- **Assumed**: a design step or an inference. Not documented as working, and not run.
- **Tested here (ops-deployed)**: run by Terje in Feb–Mar 2026 as Intune/Jamf *packages*, which is
  a different delivery than the user-run script. On 2026-09-25 this was checked in code only, not
  re-run.

| Claim | Kind |
|---|---|
| Rancher Desktop requires Windows 11 / Server 2025 (not Windows 10) | Vendor-documented |
| winget `SUSE.RancherDesktop` 1.24.0 pulls in `Microsoft.WSL` and passes `WSLINSTALLED=1` | Vendor-documented (manifest) |
| winget `Microsoft.WSL` installs WSL without Ubuntu; it needs elevation | Vendor-documented (manifest) |
| `wsl --install --no-distribution` installs the platform only; `3010`/`1641` mean restart needed | Vendor-documented (read in WindowsDeveloperConfig code, not executed) |
| At least one UAC prompt is unavoidable for WSL + Rancher Desktop | Vendor-documented |
| Intune `EnableAppInstaller` / `EnableWindowsPackageManagerCommandLineInterfaces` switch off winget for users | Vendor-documented (third-party blog + winget-cli PR). Not seen on a managed PC |
| Rancher Desktop 1.23.0/1.23.1 cannot auto-update; fixed in 1.24.0 | Vendor-documented (release notes) |
| VS Code user-scope installer needs no admin | Vendor-documented (manifest) |
| Rancher defaults under **HKCU** work without admin | Vendor-documented. **This repo only uses HKLM** (`scripts-win/rancher-desktop/install.ps1:68`) |
| Rancher Desktop winget installer is x64 only | Vendor-documented (manifest) |
| Intune can allow/block WSL; WSL MSI and Rancher MSI as plain LOB apps fail | Vendor-documented / reported in issues |
| `.wslconfig` mirrored networking, DNS tunnelling and autoProxy help on company networks | Vendor-documented |
| Jamf: Rancher Desktop reads `/Library/Managed Preferences` since 1.20 | Vendor-documented (issue #9044). This repo's mac scripts write there (`rancher-desktop-config.sh:35`) |
| Jamf: a deployment profile can suppress Rancher's admin prompt | **Assumed.** The body itself says "to be checked" |
| After the restart, per-user Rancher MSI + working WSL need **no admin** | **Assumed.** The body says "To verify". This decides whether an expired Admin on Demand breaks the flow |
| The script can self-elevate under Admin on Demand and resume after restart (scheduled task) | **Assumed.** The pattern comes from WindowsDeveloperConfig, not tried on a managed PC |
| Admin on Demand rights expire after the next restart | From this repo's [MANUAL-TEST-WINDOWS-REINSTALL.md](../../../MANUAL-TEST-WINDOWS-REINSTALL.md) (organisational process). Timing not measured |
| The 6-step unmanaged path under "What this suggests" | **Assumed.** The body says "to be proven on a machine" |
| The whole Mac + Jamf one-script path | **Assumed.** Nothing tested for a user-run install |
| DISM enables the WSL features in SYSTEM context and exits 3010 | Tested here (ops-deployed), `scripts-win/wsl2/install.ps1` |
| Rancher per-user MSI (`MSIINSTALLPERUSER=1 WSLINSTALLED=1`) in user context, pinned 1.22.0, HKLM profile | Tested here (ops-deployed), `scripts-win/rancher-desktop/install.ps1:39,465` |
| `wsl --install` fails as SYSTEM and works interactively with admin | Tested here (WSL was installed by hand on the test PC) plus WSL issues |

**Decided since landing:** Intel Macs are **out of scope**; Apple Silicon only (Terje, urb-agents #1511, 2026-09-25).

**Decided since landing:** the user-run installer lives in **client-provisioning** (option A; Terje, urb-agents #1509, 2026-09-25). Terje also wants it to replace USB-stick testing as the faster test path (#1520).

**Agreed with devcontainer-toolbox since landing (#1505, #1514):**
- **macOS 13 (Ventura) or later** (vendor-documented, Rancher Desktop 1.24 page).
- **8 GB memory / 4 CPUs are recommended**: warn, don't stop.
- Both scripts use the same user sentences:
  - Intel: "This Mac has an Intel processor. Only Apple Silicon Macs (M1 or later) are supported."
  - Too old: "This Mac runs macOS <version>. macOS 13 (Ventura) or later is required."

These checks are part d of #1510 and wait on Terje's go.

**Scope agreed with devcontainer-toolbox (urb-agents #1533, 2026-09-25): VS Code + the Dev Containers extension are this repo's to install.** Neither platform has a package for them today. The installer must:
- **Detect VS Code before installing it.** Managed PCs and Macs already get VS Code from Intune Company Portal / Jamf Self Service (`docs/OPS.md`), so a second copy must not be installed. Check both system and user installs, and find `code` on PATH or in the known install folders.
- **Install VS Code only when missing**, per user where possible. The Windows user installer needs no admin (vendor-documented, not tested). **No winget dependency**, because winget may be disabled by policy (see the Findings above).
- **Always make sure the extension is there**, as the user and not elevated: `code --install-extension ms-vscode-remote.remote-containers`. Detect it with `code --list-extensions`. DCT's host-side `.vscode/extensions.json` only *prompts*; it doesn't install.
- **Do it before the final step**, which opens VS Code in the folder.
- **No separate Intune/Jamf package for VS Code.** The organisations already deploy it; this is about the user-run installer.

Also found: `docs/OPS.md:13` says the extension "is installed automatically" from `.vscode/extensions.json`. It is a recommendation prompt the user must accept. That's a doc fix, filed as a follow-up.

Minor correction from landing: the WSL "help wanted" note is in the root
[`README.md`](../../../../README.md) ("Help wanted: Silent WSL2 install via Intune"), not in the
`scripts-win/wsl2/` README.

## Status: Backlog

**Goal**: An ordinary Windows office user — no knowledge of git, containers or Docker — runs **one script** and ends up with a professional developer's setup open in front of them.

**Hard requirement (Terje, 2026-09-25): it must work on managed machines** — Windows PCs managed by **Intune** and Macs managed by **Jamf** — where the user normally has no admin rights and installs may be blocked by policy. Unmanaged personal machines are the easier case, not the main one.

**How managed machines are handled (Terje, 2026-09-25): the user first obtains local admin rights through the organisation's process, then runs the install themselves.** So the same one script is used on managed and unmanaged machines; it uses the admin rights the user has been granted. No IT-deployed package is required.

**Priority**: High — this is who DCT is for on Windows (Terje, 2026-09-25).

**Last Updated**: 2026-09-25 (prior work in client-provisioning added)

**Related**: [PLAN-fix-windows-quickstart](https://github.com/helpers-no/devcontainer-toolbox/blob/main/website/docs/ai-developer/plans/backlog/PLAN-fix-windows-quickstart.md) (fixes the defects in today's script first), [INVESTIGATE-simplify-initial-dct-experience](https://github.com/helpers-no/devcontainer-toolbox/blob/main/website/docs/ai-developer/plans/backlog/INVESTIGATE-simplify-initial-dct-experience.md) (the first experience *inside* the container), [PLAN-windows-testing](https://github.com/helpers-no/devcontainer-toolbox/blob/main/website/docs/ai-developer/plans/backlog/PLAN-windows-testing.md)

---

## Start here: our own prior work in `helpers-no/client-provisioning`

Terje built and tested most of the pieces in February–March 2026: **[helpers-no/client-provisioning](https://github.com/helpers-no/client-provisioning)** (MIT) — "deployment scripts for setting up developer machines with container-based dev environments. Windows (Intune) and macOS (Jamf)". Every package has `install` / `detect` / `uninstall` scripts, tests, and a USB manual-test procedure; Windows packages are built as `.intunewin` by Azure Pipelines. **This investigation builds on it rather than starting over.** What it established (read 2026-09-25):

| Piece | State there | Lesson recorded |
|---|---|---|
| `scripts-win/wsl2/` | Built and tested: enables the two Windows features with DISM (works in Intune SYSTEM context), exits 3010 for the reboot. | Features alone are not WSL: after the reboot every `wsl` command asks "Press any key to install Windows Subsystem for Linux". The WSL package itself was installed **by hand** on the test PC (`wsl --install`). |
| WSL package via Intune | **Unsolved** ("help wanted" in its README; [docs/wsl-install-challenge.md](https://github.com/helpers-no/client-provisioning/blob/main/docs/wsl-install-challenge.md)). | `wsl --install` fails in SYSTEM context ([WSL #11142](https://github.com/microsoft/WSL/issues/11142), closed without fix); the Store WSL MSI fails with 1603 in SYSTEM ([#10906](https://github.com/microsoft/WSL/issues/10906)); Store/Company Portal cannot enable VirtualMachinePlatform ([#12895](https://github.com/microsoft/WSL/issues/12895)). It works **interactively with admin**, which is what the user-gets-admin-first approach relies on. |
| `scripts-win/rancher-desktop/` | Built and tested: downloads the MSI, installs **per user** (`msiexec /qn MSIINSTALLPERUSER=1 WSLINSTALLED=1`), writes the defaults profile (moby, Kubernetes off) to HKLM, starts Rancher, waits with `rdctl`, runs `docker run hello-world`. Pinned to **1.22.0** (latest is 1.24.0). | The Rancher MSI **fails in SYSTEM context** (`0x80070643`), so it runs in user context. |
| `scripts-win/devcontainer-toolbox/` | Built and tested: pulls the DCT image, installs a `devcontainer-init` command (writes `.devcontainer/devcontainer.json`) under Program Files and on PATH. | Overlaps with DCT's own `install.ps1`. |
| `scripts-mac/rancher-desktop/`, `scripts-mac/devcontainer-toolbox/` | Built and tested for Apple Silicon + Jamf: install, config, Kubernetes, uninstall, with defaults vs **locked** deployment profiles in `/Library/Managed Preferences` (root needed). | Defaults apply at first launch only; `locked` always wins. Rancher reads profiles at startup only. |
| Manual procedure | [MANUAL-TEST-WINDOWS-REINSTALL.md](https://github.com/helpers-no/client-provisioning/blob/main/docs/MANUAL-TEST-WINDOWS-REINSTALL.md) | **"Admin on Demand"** is the organisation's way to get admin: the PC restarts with admin rights, and they can **expire after the next restart** (then request again). And: *"Having admin rights via Admin on Demand is NOT the same as running PowerShell elevated — both are required."* |

What changed since then: the target user. client-provisioning was written for **ops teams deploying through Intune/Jamf**; DCT's one script is for **the office user themselves, after they have obtained admin**. The tested install logic carries over; the delivery (one script the user runs, plain-language messages, self-elevation) is new.

## The user

A normal Windows office user. They can download a file, double-click it, click "Yes" in a dialog and follow a sentence of instructions. They do **not** know what a terminal, PATH, WSL, Docker, a container, git or a "project folder" is, and they should not have to learn it to get started.

Success is: they finish without asking anyone for help, and VS Code is open in a working devcontainer.

## Current state (what the user has to do today)

From [getting-started](https://dct.sovereignsky.no/docs/getting-started):

1. Open PowerShell **as Administrator** and run `wsl --install`
2. Restart the computer
3. Download and install Rancher Desktop, and get through its first-run settings
4. Install VS Code and the Dev Containers extension
5. "Open a terminal in your project directory" and paste `irm … | iex`
6. If Windows blocks it, paste a second command with `-ExecutionPolicy Bypass`
7. Open the folder in VS Code and click "Reopen in Container"

`install.ps1` does only step 5: it writes `devcontainer.json` and pulls the image. It assumes steps 1–4 are done, and its first check fails with "Docker is not installed or not in PATH".

## Findings (2026-09-25, from vendor docs and winget manifests — not yet tried on a machine)

What has changed since [getting-started](https://dct.sovereignsky.no/docs/getting-started) was written (the page names no Rancher Desktop version; the latest is **v1.24.0**, released 2026-07-29):

| Topic | What the vendors say today | Source |
|---|---|---|
| Windows version | Rancher Desktop requires **Windows 11** (incl. Home) or Windows Server 2025, with virtualization. Our page still says "Windows 10 (build 19041+) and Windows 11". | [Rancher Desktop installation](https://docs.rancherdesktop.io/getting-started/installation/) |
| WSL before Rancher | Rancher's docs say WSL "must be installed prior to running the Rancher Desktop installer". **But** the winget package `SUSE.RancherDesktop` 1.24.0 declares `Microsoft.WSL` as a package dependency and passes `WSLINSTALLED=1`, so `winget install SUSE.RancherDesktop` installs WSL first by itself. | [winget manifest](https://github.com/microsoft/winget-pkgs/tree/master/manifests/s/SUSE/RancherDesktop/1.24.0) |
| WSL distro | `wsl --install` (what our page tells the user) also installs **Ubuntu**, which then asks the user to create a Linux username and password. Rancher Desktop does not need that distro; for our user it is a confusing extra step. The winget `Microsoft.WSL` package installs WSL without a distro. | [Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install) |
| Admin | `wsl --install` needs an admin PowerShell. The winget `Microsoft.WSL` package is `elevationRequired`. Rancher Desktop's winget package is machine-scope; its own installer offers "just for the current user", but "an Admin's intervention is required during the installation process" for its privileged service. So **at least one elevation (UAC prompt) is unavoidable** for WSL + Rancher. | winget manifests; Rancher docs |
| Restart | Microsoft still says to restart after `wsl --install`. Microsoft's own current setup code runs `wsl --install --no-distribution` and treats exit codes `3010`/`1641` as "installed, restart required" (verified in `microsoft/WindowsDeveloperConfig` `src/windows-dev-config/steps/wsl.ps1`, 2026-09-25). The Rancher winget package also lists `3010` as success. So the script **must** handle a restart. | Install WSL; WindowsDeveloperConfig; winget manifest |
| WSL without Ubuntu | `wsl --install --no-distribution` installs the WSL platform without a distro (verified: Microsoft's setup code above uses exactly this). | WindowsDeveloperConfig |
| `winget` on managed machines | Intune / Group Policy can switch winget off for users: `EnableAppInstaller` = Disabled makes every winget command fail with "disabled by Group Policy"; `EnableWindowsPackageManagerCommandLineInterfaces` blocks the CLI while Intune itself can still install. These are device policies (HKLM). So on a managed machine **winget may be unavailable**, and the script needs a fallback (download the official MSI from the Rancher Desktop GitHub release, the VS Code user installer from Microsoft). | [Intune DesktopAppInstaller policies](https://petervanderwoude.nl/post/configuring-windows-package-manager/), [winget-cli #3524](https://github.com/microsoft/winget-cli/pull/3524) |
| Rancher auto-update | Rancher Desktop 1.23.0 and 1.23.1 cannot auto-update (the updater download fails); users on those versions must install 1.24.0 manually. Fixed from 1.24.0 on. Relevant for the "second run / repair" question. | [RD v1.24.0 release notes](https://github.com/rancher-sandbox/rancher-desktop/releases/tag/v1.24.0) |
| Silent install | Rancher: `silent` install mode supported. VS Code (`Microsoft.VisualStudioCode` 1.139.0): Inno installer with both `user` and `machine` scope, so it **installs without admin** in user scope. | winget manifests |
| Rancher settings | Deployment profiles can preset every preference (for example container engine `moby`, Kubernetes off). They live in the registry: `HKCU\Software\Policies\Rancher Desktop\Defaults` (per user, no admin) or `HKLM\...` (machine-wide, admin or group policy). The script can write the HKCU defaults so the user never opens Rancher's settings. | [Deployment profiles](https://docs.rancherdesktop.io/getting-started/deployment/) |
| Architecture | The Rancher Desktop winget installer is **x64 only**; Windows on ARM laptops cannot use this path. | winget manifest |

### What this suggests for an unmanaged PC (to be proven on a machine)

A one-script path with a single UAC prompt looks possible on a Windows 11 x64 machine where the user can elevate:

1. `winget install Microsoft.VisualStudioCode --scope user` (no admin)
2. `code --install-extension ms-vscode-remote.remote-containers`
3. Write the Rancher Desktop defaults to `HKCU` (moby, Kubernetes off)
4. `winget install SUSE.RancherDesktop --silent` (one UAC prompt; pulls in WSL without Ubuntu)
5. If the exit code means "restart needed": say so in one sentence, restart, and continue by itself afterwards
6. Create the user's work folder, write `devcontainer.json`, start Rancher Desktop, wait until it is ready, open VS Code in the folder

Unknowns that decide it: whether `winget` is present and allowed on managed machines (Q3), whether the WSL package actually needs the restart on current Windows 11 (Q2), and what happens when the user cannot elevate (Q1).

## Managed machines (Intune, Jamf) — findings 2026-09-25

The user gets local admin first (see the requirement at the top), so the tables below matter mainly for **what the script needs admin for, and what policy can still block even with admin**. The Intune/Jamf deployment routes are kept as a fallback for organisations that will not grant admin.

### Windows + Intune

| Part | Needs admin? | How IT can deploy it | Source |
|---|---|---|---|
| WSL platform | Yes | As an Intune Win32 app (for example a wrapped `wsl --install --no-distribution`, or the WSL MSI wrapped with the Win32 content prep tool; importing the WSL MSI as a plain LOB app is reported not to work). Intune can also **allow or block WSL** as a Windows component: if IT blocks it, DCT cannot run. | [WSL for your company](https://learn.microsoft.com/en-us/windows/wsl/enterprise), [microsoft/WSL #10906](https://github.com/microsoft/WSL/issues/10906), [markorr321/Deploy-WSL-Intune](https://github.com/markorr321/Deploy-WSL-Intune) (4 stars, no licence: ideas only) |
| WSL network settings | Set per user in `.wslconfig` | Microsoft recommends `networkingMode=mirrored`, `dnsTunneling=true`, `autoProxy=true` on company networks (VPNs, proxies). The user script can write these. | [WSL for your company](https://learn.microsoft.com/en-us/windows/wsl/enterprise) |
| Rancher Desktop | Yes (privileged service), and **WSL must already be there** | Win32 app running `msiexec /i Rancher.Desktop.Setup.<ver>.msi /qn WSLINSTALLED=1` (maintainer: "`WSLINSTALLED=1` is a promise that a compatible version is already installed"). Deploying the MSI as a plain LOB app is reported to fail (issue still open). | [rancher-desktop #7356](https://github.com/rancher-sandbox/rancher-desktop/issues/7356) |
| Rancher Desktop settings | HKLM needs admin; HKCU does not | IT sets and optionally locks defaults (container engine `moby`, Kubernetes off) under `HKLM\Software\Policies\Rancher Desktop` via Intune/Group Policy; or the user script writes the HKCU defaults. | [Deployment profiles](https://docs.rancherdesktop.io/getting-started/deployment/) |
| VS Code | No (user installer) | Intune (Enterprise App Catalog / Win32 app / winget via Intune), or the user script in user scope. | winget manifest |
| Dev Containers extension | No | The user script: `code --install-extension ms-vscode-remote.remote-containers`. | — |
| `winget` for the user | — | May be switched off for users by Intune (`EnableAppInstaller`, `EnableWindowsPackageManagerCommandLineInterfaces`). The user script must not depend on it. | see Findings |

### Mac + Jamf

| Part | How IT can deploy it | Source |
|---|---|---|
| Rancher Desktop | Jamf package. | — |
| Rancher Desktop settings | A Jamf **configuration profile** for `io.rancherdesktop.profile.defaults` / `.locked`. Rancher Desktop reads MDM-pushed settings from `/Library/Managed Preferences` **since 1.20** (older versions only read `/Library/Preferences`). | [rancher-desktop #9044](https://github.com/rancher-sandbox/rancher-desktop/issues/9044), [Deployment profiles](https://docs.rancherdesktop.io/getting-started/deployment/) |
| Admin prompt from Rancher | Rancher asks for an admin password for its privileged helper; a deployment profile can preset whether it does (to be checked: which setting, and what breaks without it). | [Jamf community thread](https://community.jamf.com/t5/jamf-pro/rancher-desktop-administrative-access/td-p/330030) |
| VS Code | Jamf package or App Installers. | — |

### What this means for the design

One script, used on managed and unmanaged machines alike, reusing client-provisioning's tested steps:

1. **Check admin rights first, and elevate.** If the user has no admin rights, stop before changing anything and say in plain words what to do: *"This installation needs administrator rights on your PC. On a work PC, ask for temporary administrator rights (for example Admin on Demand), then run this again."* If they have admin rights but the window is not elevated, the script elevates itself (UAC) rather than telling the user to "run as administrator"; client-provisioning found that users trip over exactly this.
2. **Before the restart, with admin:** `wsl --install --no-distribution` (installs the WSL package and turns on the features; DISM as fallback), and anything else that needs admin.
3. **Restart only if Windows needs it**, then resume after login.
4. **After the restart — needs no admin if at all possible**, because Admin on Demand may have expired: Rancher Desktop **per-user** install (`MSIINSTALLPERUSER=1 WSLINSTALLED=1`, tested in client-provisioning) with its defaults written to **HKCU** instead of HKLM, VS Code (user scope), the Dev Containers extension, `.wslconfig` network settings, the work folder and `devcontainer.json`; start Rancher, wait with `rdctl`, open VS Code. **To verify:** that the per-user Rancher MSI and a working WSL really need no admin after the restart (the Rancher privileged service does need admin, but is optional).
5. **Detect what policy still blocks even with admin**, and name it plainly: WSL disallowed by Intune, virtualization off in BIOS, winget disabled (the script does not use winget; it downloads the official installers, as client-provisioning does).

**Fallback for organisations that will not grant admin:** client-provisioning's Intune/Jamf packages, once its open WSL problem is solved. Not the first thing to build.

## Prior art — who has built something like this (searched 2026-09-25)

| Project | What it does | Fit for DCT |
|---|---|---|
| **[microsoft/WindowsDeveloperConfig](https://github.com/microsoft/WindowsDeveloperConfig)** (MIT, ~2,200 stars, actively maintained) | Takes a clean Windows 11 machine to a developer workstation with **one pasted command** (`& ([scriptblock]::Create((irm <url>)))`). Elevates itself, installs WSL with `--no-distribution`, warns and restarts after 10 seconds, and **resumes after login via a scheduled task** (a second UAC prompt). Built on `winget configure`: one `configuration.winget` file per "workload" (dotnet, python, go, typescript, …) plus shared helpers (`preflight.ps1`, `enable-winget-configure.ps1`, `apply-configuration.ps1`, `invoke-retry.ps1`). | **Closest match, and the pattern to follow.** It has **no container workload**: nothing for Docker, Rancher Desktop or Dev Containers. A DCT workload (Rancher Desktop + HKCU defaults + VS Code + Dev Containers extension + `devcontainer.json`) fits its model exactly. Options: reuse its structure in `install.ps1` (MIT, with attribution), or contribute a `devcontainers` workload upstream. Its tone and plain-language steps are aimed at developers, so our messages must be simpler. |
| [WinGet Configuration](https://developer.microsoft.com/blog/winget-configuration-set-up-your-dev-machine-in-one-command/) (`winget configure -f file.winget`) | Microsoft's declarative "set up your dev machine in one command": a YAML file lists packages and settings, applied idempotently, one admin approval. | The engine under WindowsDeveloperConfig. Gives us idempotent re-runs (question 6) for free. Blocked wherever winget is blocked. |
| [rozicdejan/wsl-with-rancher-desktop](https://github.com/rozicdejan/wsl-with-rancher-desktop) (0 stars, **no licence**) | PowerShell script: detects virtualization/BIOS, enables WSL features, installs Ubuntu and Rancher Desktop from a local MSI, configures moby + Kubernetes off, resumes after reboot. | Shows the same steps are doable, including virtualization detection (question 7). Requires an admin PowerShell and a manually downloaded MSI, so not for our user. **No licence: read for ideas only, do not copy code.** |
| [Boxstarter](https://github.com/Microsoft/windows-dev-box-setup-scripts) (Chocolatey-based, used by Microsoft's older dev-box scripts) | Reboot-resilient install scripts. | Superseded by WinGet Configuration. Known issue: after a reboot it does not always log back in to resume. Not recommended. |
| [DevPod](https://devpod.sh/) (desktop app, winget `Skvetter.DevPod`) | A GUI for creating devcontainer workspaces on local Docker or cloud providers. | A developer tool with developer vocabulary (providers, workspaces). Does not install Docker/WSL for the user. Not a fit for office users. |

Nobody found so far combines "install WSL + Rancher Desktop + VS Code + Dev Containers" with "open a ready devcontainer" in one step for non-developers. That gap is what DCT's Windows installer would fill.

## Questions to Answer

1. **Admin rights.** Which steps need admin (WSL, virtualization features, Rancher Desktop, VS Code)? Many office machines are managed (Intune) and the user is not a local admin. What does the script do then: stop with a plain message for IT, or can every step run per-user?
2. **Restart.** `wsl --install` usually needs a restart. How does the script resume after it without the user re-finding and re-running it (a scheduled task, a Start-menu shortcut, a "run me again" message)?
3. **Installing the tools.** Is `winget` present and allowed on managed Windows 11? (It can be disabled by Intune policy; see Findings.) If not, what is the fallback (direct download of the official installers)? Which Rancher Desktop settings must be set for DCT (container engine `moby`, Kubernetes off/on), and can they be set without the user opening Rancher's settings?
4. **How the user starts it.** A pasted `irm | iex` line requires opening PowerShell. Is a downloadable `.cmd`/`.ps1` they double-click better? What do SmartScreen and "Mark of the Web" do to a downloaded script, and how do we keep that to one click?
5. **Where their work lives.** The user has no "project folder". Should the script create one (for example `Documents\DevContainer-Toolbox\<name>`), and then open VS Code in it (`code <folder>`) so "Reopen in Container" is the only thing left to click, or can the script trigger that too?
6. **Second run.** Running it again must be safe: detect what is already installed, repair what is broken, and never lose the user's files.
7. **What can go wrong on real machines.** Virtualization off in BIOS, not enough disk space, Docker Desktop already installed, corporate proxy, antivirus blocking WSL. For each: how do we detect it, and what plain sentence tells the user (or their IT) what to do?
8. **Language.** Every message in plain language, with the next action spelled out. Norwegian as well as English?
9. **Testing.** How do we test this repeatably: a clean Windows VM snapshot, a GitHub `windows-latest` runner (no nested virtualization, so WSL/Rancher cannot run there), or both?

## Options

### Option A: Guide, don't install

The script checks each prerequisite and, when one is missing, opens the right download page and waits.

- Cons: several installs and a restart done by the user; impossible on a managed machine without admin. **Does not meet the goal.**

### Option B: The user script installs everything, with one UAC prompt

The WindowsDeveloperConfig way: elevate once, install WSL + Rancher Desktop + VS Code, resume after the restart.

- Works on unmanaged machines where the user can elevate.
- Works on managed machines too, **once the user has obtained local admin** (the organisation's process). Must not depend on winget, and must finish every admin step before the restart.

### Option C: IT kit + a no-admin user script

IT deploys the admin-only parts centrally through Intune or Jamf; the user's script does only per-user work.

- Only needed where the organisation will not grant the user local admin. Kept as a fallback.

## Recommendation

**Option B, one script for every machine**, assembled from client-provisioning's tested steps (with WindowsDeveloperConfig as the pattern for self-elevation and resume after restart), with these rules from the managed-machine requirement:

1. Check for admin rights first; if missing, explain how to get them and stop.
2. All admin-only steps before the restart; everything after the restart needs no admin.
3. No dependency on winget: download the official installers directly, as client-provisioning does.
4. Plain-language messages for everything policy can still block.

Windows first, then the same approach for Mac (`install.sh`). Option C's IT kit only if an organisation will not grant admin.

## Next Steps

- [ ] Decide with Terje where the one script lives: in this repo (`install.ps1` / `install.sh`, what the Quick Start runs) or in `client-provisioning` (which already has the tested pieces), and how the two share code
- [ ] Update client-provisioning's Rancher Desktop pin from 1.22.0 to 1.24.0 (1.23.x cannot auto-update)
- [ ] On a managed Windows 11 PC with Admin on Demand: prove steps 1–4 by hand, and answer the open question — does anything after the restart need admin?
- [ ] Same on a managed Mac (Jamf)
- [ ] Write the PLAN file for the Windows installer from what worked

