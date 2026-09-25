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
| **1** | Finish [PLAN-adopt-fleet-template](../active/PLAN-adopt-fleet-template.md) (urb-agents #1498): PR, report | Assigned; every later plan uses the new structure |
| **2** | [INVESTIGATE-windows-one-script-install](INVESTIGATE-windows-one-script-install.md): desk work that needs no machine — map each design step to the existing `scripts-win/` code, list what is reusable | High priority (Terje); can progress before test machines exist |

## Waiting on someone — ordered by what it unblocks

| What | Who | Since | Unblocks | Raised |
|---|---|---|---|---|
| A managed Windows 11 PC (Intune, Admin on Demand) and a Jamf Mac to test on | Terje | 2026-09-25 | Every untested claim in the one-script investigation | #1498 |
| Where the one script lives (this repo or devcontainer-toolbox) and how code is shared | Terje, with devcontainer-toolbox | 2026-09-25 | Writing the Windows installer PLAN | #1492 |
| PR / merge of the template adoption | ops-dev / Terje | 2026-09-25 | Closing #1498 | #1498 |

## If Terje wants work started, these rank highest

1. Rancher Desktop pin 1.22.0 → 1.24.0 in `scripts-win/rancher-desktop/` (1.23.x cannot auto-update) — a shipping-package change, so it needs his go — from [`index.md`](index.md)
2. The one-script Windows installer PLAN, once item 2 above and the test machine exist

When this file's one-liner changes, refresh `fleet/status/client-provisioning.md` with
`urb publish-status --via-bus` (do not write that file by hand).
