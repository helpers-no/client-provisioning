# CLAUDE.md — Client Provisioning

This repo (`client-provisioning`) holds host installers for managed machines: bash scripts for Macs
deployed via Jamf, and PowerShell scripts built into `.intunewin` packages for Windows via Intune.

The repo uses the URB AI-developer workflow. **Before doing anything else, read the docs in
[`docs/ai-developer/`](docs/ai-developer/).**

## Start here (in order)

1. **[`docs/ai-developer/project-client-provisioning.md`](docs/ai-developer/project-client-provisioning.md)** —
   the authoritative description of this repo: layout, packages, commands, git host, devcontainer,
   and the non-negotiable contracts. **Read this first.** Also read
   [`project-azure-devops.md`](docs/ai-developer/project-azure-devops.md) (CI pipeline and wiki).
2. **[`docs/ai-developer/README.md`](docs/ai-developer/README.md)** — how the AI-developer system
   works and the full reading order.
3. Reference as needed: `WORKFLOW.md`, `PLANS.md`, `GIT.md`, `AZURE-DEVOPS.md` (applies here — CI
   runs in Azure Pipelines), `DEVCONTAINER.md` (applies — DCT), `WORKTREE.md`, `COORDINATION.md`,
   `VERIFICATION.md`, `SECURITY.md`.

## Key rules

- **Always ask before starting** — ask whether to create a `PLAN-*.md` or `INVESTIGATE-*.md` before doing anything. Read [PLANS.md](docs/ai-developer/PLANS.md) before creating any plan file.
- **Ask before git writes that carry risk** — push to a shared branch, PR, merge, release/tag, and any change under `scripts-win/` or `scripts-mac/`. Commits of docs and plans on your own feature branch are free. Anything published here runs with admin rights on other people's managed machines. (Scope set by ops-dev on urb-agents #1498; see the Contracts in the project doc.)
- **Every script must follow the standard** — see [rules/script-standard.md](docs/ai-developer/rules/script-standard.md), [rules/bash.md](docs/ai-developer/rules/bash.md) and [rules/powershell.md](docs/ai-developer/rules/powershell.md).
- **Validate before committing** — `bash docs/ai-developer/tools/validate-bash.sh` and `bash docs/ai-developer/tools/validate-powershell.sh`

## Fleet

**Fleet coordination is not in this repo.** The protocol lives in `terchris/urb-agents`
(`protocol/communication.md`), read remotely — do not clone urb-agents and do not copy `protocol/`
here. This agent's inbox is a **query, not a directory**: `~/.local/bin/urb inbox --id client-provisioning`,
which is open issues labelled `to:client-provisioning`. Ask questions on the bus task
(`urb update <n> --state input-required`), not in an interactive prompt. See
[`COORDINATION.md`](docs/ai-developer/COORDINATION.md).

**There is no file bus.** `talk/`, `TALK.md` and `mailboxes/` were all retired; nothing reads them.

Plans live in [`docs/ai-developer/plans/`](docs/ai-developer/plans/) (`backlog/`, `active/`,
`completed/`). Current triage is [`plans/backlog/1PRIORITY.md`](docs/ai-developer/plans/backlog/1PRIORITY.md).
Keep it true on a change, not on a timer.
