---
mdx:
  format: md
title: Backlog — index
sidebar_label: Backlog (index)
sidebar_position: 0
---

# Backlog — index

What each open backlog item **is**, in one line. [`1PRIORITY.md`](1PRIORITY.md) says what to
**do next**. INVESTIGATEs stay here until every child PLAN ships; PLANs live in `active/` while
in progress.

| Item | What it does | Priority |
|---|---|---|
| [INVESTIGATE-windows-one-script-install.md](INVESTIGATE-windows-one-script-install.md) | One script an office user runs (after getting admin) that readies a managed Windows PC — WSL, Rancher Desktop, VS Code, Dev Containers — then hands over to DCT's installer. Handed over by devcontainer-toolbox. **Untested on any managed machine.** | High (Terje, 2026-09-25) |
| [PLAN-rancher-124-and-host-checks.md](../active/PLAN-rancher-124-and-host-checks.md) | Rancher Desktop 1.24 + Windows 11/x64 checks on Windows; Mac Rancher scripts to legacy (Jamf installs natively). Approved in principle on #1510, waiting on review | High |
| [PLAN-github-actions-ci.md](../active/PLAN-github-actions-ci.md) | CI on every PR: bash + PowerShell validation, and a .intunewin build + test with **no upload**. The only way to validate PowerShell anywhere in the fleet | **Highest**: gates PR #18 |
| [PLAN-fix-mac-test-startup-line.md](PLAN-fix-mac-test-startup-line.md) | The 8/9 pre-existing startup-line failures in `scripts-mac/devcontainer-toolbox/tests`, so the folder can join CI | Medium |
| [INVESTIGATE-wsl-intune.md](INVESTIGATE-wsl-intune.md) | Everything known about deploying WSL2 via Intune (SYSTEM-context failures, what was done by hand). The IT-deployed fallback (Option C) of the one-script investigation. | Low — fallback |
