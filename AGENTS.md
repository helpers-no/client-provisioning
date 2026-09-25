# AGENTS.md

This file is the entry point for Codex / OpenAI-family tooling and other agents. Same content as
[`CLAUDE.md`](CLAUDE.md) — see that file for the project orientation.

## Short version

- This repo is **`client-provisioning`** — host installers for managed Windows (Intune) and macOS (Jamf) machines.
- Read [`docs/ai-developer/project-client-provisioning.md`](docs/ai-developer/project-client-provisioning.md)
  first; it is the authoritative project doc.
- Read [`docs/ai-developer/README.md`](docs/ai-developer/README.md) next for the AI-developer
  workflow.
- Plans live in [`docs/ai-developer/plans/`](docs/ai-developer/plans/).
- **Anything published from this repo runs with admin rights on other people's managed machines.**
  Ask before push, PR, merge, release, or any change under `scripts-win/` / `scripts-mac/`.
- Fleet work arrives on the bus in `terchris/urb-agents`, not in this repo: the inbox is a query — `~/.local/bin/urb inbox --id client-provisioning` (open issues labelled `to:client-provisioning`). There is no mailbox directory.

For the always-critical rules and the full Start-Here reading order, see [`CLAUDE.md`](CLAUDE.md).
