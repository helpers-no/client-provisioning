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
| **1** | [PLAN-github-actions-ci](../active/PLAN-github-actions-ci.md) task 1.5, and [PLAN-fix-mac-test-startup-line](PLAN-fix-mac-test-startup-line.md): get the test folders into CI | CI is the gate, and it doesn't yet look at `tests/` |
| **2** | The user-run install script (approved as 1 on #1520): write `PLAN-windows-user-installer.md` from [INVESTIGATE-windows-one-script-install](INVESTIGATE-windows-one-script-install.md). Step one is a read-only check script, which is also how to test it on Terje's PC. **It must also detect VS Code and install it per user when missing** (#1533). **The Dev Containers extension is DCT's**: its script installs it, and ours only checks afterwards. The PR #18 test showed `-ExecutionPolicy Bypass` is not blocked there | Terje's top ask after CI; it's also the faster test path |

## Waiting on someone — ordered by what it unblocks

| What | Who | Since | Unblocks | Raised |
|---|---|---|---|---|
| **Upload the 1.24 packages to Intune**, and optionally prove the upgrade path on a PC with Rancher < 1.24 first (it has never run) | Terje | 2026-09-25 | Rancher 1.24 reaching managed PCs | handover item |
| Make the CI checks required on `main` (branch protection) | Terje | 2026-09-25 | CI being a real gate, not advisory | #1528 |
| Which of the four asks to start: user-run script (also the faster test), end-user README, web page (`helpers-no/sovereignsky-site`), GitHub Actions `.intunewin` build and public release | Terje | 2026-09-25 | Everything after the plan review; the installer lives **here** (decided, #1509) | #1520 |
| A **blank** Jamf Mac, for the clean-install path only. Deferred: Terje would have to ask the Jamf admin, and nothing needs it yet. **tecMacWork** (Jamf-managed, Rancher already installed) covers detection, second run, and parts a/d of #1510 | Terje / Jamf admin | 2026-09-25 | Proving the Mac clean-install path | #1510 |
| DCT's **first pinned release** (tag, `SHA256SUMS`, `host-requirements.json`, pinned image). `dct-init` itself is done (DCT 1.9.0) | devcontainer-toolbox | 2026-09-25 | Shipping anything that calls DCT; retiring `devcontainer-init` (#1510 c) | #1505, #1543 |

## If Terje wants work started, these rank highest

*Approved on #1520, in this order (CI, 4a, is **live** since PR #20):* **1** the user-run install script (also the faster test), **2** the end-user README, **3** the web page (PR to `helpers-no/sovereignsky-site`, AI-drafted texts go to Terje for review). **4b** (public release of `.intunewin`) is *later*.

1. Part c (retire `devcontainer-init`): answered "later"; it waits on devcontainer-toolbox
2. The user-run Windows installer PLAN. Its location is decided (this repo, #1509), and the start waits on #1520

When this file's one-liner changes, refresh `fleet/status/client-provisioning.md` with
`urb publish-status --via-bus` (do not write that file by hand).
