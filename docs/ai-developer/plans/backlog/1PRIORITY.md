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
| **1** | [INVESTIGATE-windows-one-script-install](INVESTIGATE-windows-one-script-install.md): desk work that needs no machine. Map each design step to the existing `scripts-win/` code, list what is reusable, and add the DCT handover contract (urb-agents #1505) to it | High priority (Terje). It can move before test machines exist, and the contract shapes the design |
| **2** | Write the step-by-step test script for Terje's managed Windows PC. It is **not clean** (Rancher 1.24.0 and WSL already installed). Round 1 only reads the machine's state and changes nothing. Send it to terje as its own item | Terje offered the PC (#1512); a ready script keeps his machine time short |

## Waiting on someone — ordered by what it unblocks

| What | Who | Since | Unblocks | Raised |
|---|---|---|---|---|
| Where the one script lives (this repo or devcontainer-toolbox), and how code is shared | Terje, with devcontainer-toolbox | 2026-09-25 | The Windows installer PLAN, and the command DCT shows users (#1505 point 3) | #1509 |
| Go for the script changes: Windows 11 build ≥ 22000 + x64 checks, Rancher 1.22.0 → 1.24.0 (win + mac), `devcontainer-init` calling DCT's script, Apple Silicon check on mac (Intel out of scope, decided on #1511) | Terje | 2026-09-25 | Meeting DCT's host requirements (#1505 points 1, 4) | #1510 |
| A Jamf Mac to test on (only needed when the Mac work starts) | Terje | 2026-09-25 | The Mac side of the investigation | #1512 (Windows half answered) |
| DCT: release assets + `SHA256SUMS`, a pinned image, a disk-space figure, and the `devcontainer-init` behaviours moved into its script | devcontainer-toolbox | 2026-09-25 | Pinned, verified handover (#1505 points 2, 4) | #1505 |

## If Terje wants work started, these rank highest

1. The script changes in the waiting table above. They ship packages, so each one needs his go
2. The one-script Windows installer PLAN, once its location is decided and a test machine exists

When this file's one-liner changes, refresh `fleet/status/client-provisioning.md` with
`urb publish-status --via-bus` (do not write that file by hand).
