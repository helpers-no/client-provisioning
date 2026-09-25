---
mdx:
  format: md
title: '1PRIORITY — what this agent does next'
sidebar_label: '1PRIORITY (triage)'
sidebar_position: 1
---

# 1PRIORITY — what this agent does next

**Last updated: 2026-09-25** · agent `client-provisioning` · state **working**

A triage view, ordered by *what each item unblocks* — not a roadmap and not a plan.
[`index.md`](index.md) says what every backlog item **is**; this file says what to **do next**
and what is stuck behind whom. Kept current on a change, not on a schedule.

Fleet work is on the bus in `terchris/urb-agents` —
`~/.local/bin/urb inbox --id client-provisioning`; there is no mailbox directory.

---

## Do next — mine, unblocked

| # | What | Why this one |
|---|---|---|
| **1** | [PLAN-rancher-124-and-host-checks](../active/PLAN-rancher-124-and-host-checks.md) is **draft PR #18, with CI green** (validator 13/13, unit tests pass, builds OK), and now includes **upgrade in place** (Terje: A, #1522). **Terje's PC test passed (#1527).** Waiting on the merge ask (#1529); Terje then uploads to Intune | Approved shipping work; the Windows packages meet DCT's requirements |
| **2** | [INVESTIGATE-windows-one-script-install](INVESTIGATE-windows-one-script-install.md): desk work that needs no machine. Map each design step to the existing `scripts-win/` code, list what is reusable, and add the DCT handover contract (urb-agents #1505) to it | High priority (Terje). It can move before test machines exist, and the contract shapes the design |
| **3** | Write the step-by-step test script for Terje's managed Windows PC. It is **not clean** (Rancher 1.24.0 and WSL already installed). Round 1 only reads the machine's state and changes nothing. Send it to terje as its own item | Terje offered the PC (#1512); a ready script keeps his machine time short |

## Waiting on someone — ordered by what it unblocks

| What | Who | Since | Unblocks | Raised |
|---|---|---|---|---|
| Merge PR #18 (both gates passed: CI and PC test) | ops-dev | 2026-09-25 | Terje uploading the 1.24 packages to Intune | #1529 |
| Make the CI checks required on `main` (branch protection) | Terje | 2026-09-25 | CI being a real gate, not advisory | #1528 |
| Which of the four asks to start: user-run script (also the faster test), end-user README, web page (`helpers-no/sovereignsky-site`), GitHub Actions `.intunewin` build and public release | Terje | 2026-09-25 | Everything after the plan review; the installer lives **here** (decided, #1509) | #1520 |
| A **blank** Jamf Mac, for the clean-install path only. Deferred: Terje would have to ask the Jamf admin, and nothing needs it yet. **tecMacWork** (Jamf-managed, Rancher already installed) covers detection, second run, and parts a/d of #1510 | Terje / Jamf admin | 2026-09-25 | Proving the Mac clean-install path | #1510 |
| DCT: release assets + `SHA256SUMS`, a pinned image, a disk-space figure, and the `devcontainer-init` behaviours moved into its script | devcontainer-toolbox | 2026-09-25 | Pinned, verified handover (#1505 points 2, 4) | #1505 |

## If Terje wants work started, these rank highest

*Approved on #1520, in this order (CI, 4a, is **live** since PR #20):* **1** the user-run install script (also the faster test), **2** the end-user README, **3** the web page (PR to `helpers-no/sovereignsky-site`, AI-drafted texts go to Terje for review). **4b** (public release of `.intunewin`) is *later*.

1. Part c (retire `devcontainer-init`): answered "later"; it waits on devcontainer-toolbox
2. The user-run Windows installer PLAN. Its location is decided (this repo, #1509), and the start waits on #1520

When this file's one-liner changes, refresh `fleet/status/client-provisioning.md` with
`urb publish-status --via-bus` (do not write that file by hand).
