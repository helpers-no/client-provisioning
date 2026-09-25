# project-client-provisioning

The authoritative description of **this** repository. The framework docs (`WORKFLOW.md`,
`PLANS.md`, `GIT.md`, …) yield to this file when they disagree.

## What this repo is

**Host installers for managed machines.** The repo holds deployment scripts that prepare Windows
PCs managed by **Intune** and Macs managed by **Jamf**: WSL2, Rancher Desktop, the devcontainer
toolbox bootstrap, and diagnostics. The ops team edits the scripts in a devcontainer and validates
them. Mac scripts are copied into Jamf. Windows scripts are built into `.intunewin` packages by CI
and uploaded to Intune.

The split with the sibling repo was set by Terje on 2026-09-25. **This repo owns "the machine is
ready"**: WSL, Rancher Desktop, VS Code and the Dev Containers extension, elevation,
restart/resume, and the Intune/Jamf packages. **devcontainer-toolbox owns "the project is
ready"**: `devcontainer.json`, the image, and everything inside the container.

## What it builds / does not build

- Builds: bash scripts for macOS (Jamf); PowerShell scripts and `.intunewin` packages for Windows
  (Intune); the tests and validators for both.
- Does not build: the devcontainer image or its tools (that is
  [devcontainer-toolbox](https://github.com/helpers-no/devcontainer-toolbox)); the MDM
  configuration itself (it lives in Intune and Jamf, not in git).

## Layout

| Path | What |
|---|---|
| `scripts-mac/<package>/` | Bash, macOS via Jamf. Target: **macOS bash 3.2**, Apple Silicon |
| `scripts-win/<package>/` | PowerShell, Windows via Intune |
| `docs/` | Ops-team docs, published as the Azure DevOps code wiki (see [project-azure-devops.md](project-azure-devops.md)) |
| `docs/ai-developer/` | **This folder**, the AI-developer system. There is no second copy |
| `azure-pipelines.yml`, `.azure-pipelines/` | CI: validates and builds `.intunewin` packages ([CICD.md](../CICD.md)) |
| `.githooks/pre-commit` | Auto-bumps the `SCRIPT_VER` patch version on changed `.sh`/`.ps1` files |
| `.devcontainer/`, `.devcontainer.extend/` | DCT devcontainer |

Each folder under `scripts-mac/` or `scripts-win/` is a **package**: a group of related
deployment scripts with a README and a `tests/` folder.

| Package | Platform | Scripts | Tests |
|---|---|---|---|
| `rancher-desktop/` | mac | 4 | 14 |
| `devcontainer-toolbox/` | mac | 3 | 9 |
| `urbalurba-infrastructure-stack/` | mac | — | — (planned, not started) |
| `rancher-desktop/` | win | 4 | 4 |
| `wsl2/` | win | 3 | 6 |
| `devcontainer-toolbox/` | win | 5 | 5 |
| `diagnostics/` | win | 1 | — |

## The script standard — this repo's own, and it wins on script content

The fleet template governs **process**: plans, handovers, and the `AGENTS.md` entry point. It says
nothing about how a script is written. Here that is defined by this repo's own standard:

1. **Shared standard**: metadata, help format, logging, error codes, for every language.
   [rules/script-standard.md](rules/script-standard.md). Human-facing summary:
   [docs/SCRIPT-STANDARDS.md](../SCRIPT-STANDARDS.md).
2. **Language rules**: syntax, templates, validation and platform gotchas.
   [rules/bash.md](rules/bash.md), [rules/powershell.md](rules/powershell.md).
3. **Templates**: `templates/bash/script-template.sh`, `templates/powershell/script-template.ps1`,
   `templates/README-template.md`.

**Every script follows the standard**, including test scripts, helpers and library scripts.

Manual end-to-end procedures on real machines:
[docs/MANUAL-TEST-WINDOWS-REINSTALL.md](../MANUAL-TEST-WINDOWS-REINSTALL.md) (USB-stick full
reinstall).

## Commands

Run everything from the repo root, inside the devcontainer.

```bash
# Validate (syntax, help, metadata, shellcheck / PSScriptAnalyzer)
bash docs/ai-developer/tools/validate-bash.sh                        # all mac packages
bash docs/ai-developer/tools/validate-bash.sh rancher-desktop        # one package
bash docs/ai-developer/tools/validate-bash.sh rancher-desktop/tests  # a subfolder
bash docs/ai-developer/tools/validate-powershell.sh                  # all win packages
bash docs/ai-developer/tools/validate-powershell.sh wsl2

# Bump SCRIPT_VER across a package (minor/major; the pre-commit hook does patch)
bash docs/ai-developer/tools/set-version-bash.sh rancher-desktop
bash docs/ai-developer/tools/set-version-powershell.sh diagnostics
```

### Version management

This rule moved here from the old `WORKFLOW.md`, because the template workflow has no version step.

Before pushing or merging a change to a package, ask: **"Should we bump the version for this
change?"** `SCRIPT_VER` is shown in help output and tells ops which version is deployed.

- PATCH (0.0.x): bug fixes, small improvements. `.githooks/pre-commit` does this automatically
  for changed scripts that already exist in `HEAD`
- MINOR (0.x.0): new features, new scripts. Use `set-version-*.sh`
- MAJOR (x.0.0): breaking changes. Use `set-version-*.sh`

Docs-only changes do not bump a version. The repo has no `version.txt`.

## IMPLEMENTATION RULES blocks

Copy the matching block to the top of every plan or investigation file in `plans/<folder>/`.

### Bash work

```markdown
> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) — The implementation process
> - [PLANS.md](../../PLANS.md) — Plan structure and best practices
> - [rules/script-standard.md](../../rules/script-standard.md) — Shared script standard
> - [rules/bash.md](../../rules/bash.md) — Bash-specific rules
>
> **UPDATE THIS PLAN AS YOU WORK:** Mark tasks `[x]` when done, add `— DONE` to phase headers, update status.
```

### PowerShell work

```markdown
> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) — The implementation process
> - [PLANS.md](../../PLANS.md) — Plan structure and best practices
> - [rules/script-standard.md](../../rules/script-standard.md) — Shared script standard
> - [rules/powershell.md](../../rules/powershell.md) — PowerShell-specific rules
>
> **UPDATE THIS PLAN AS YOU WORK:** Mark tasks `[x]` when done, add `— DONE` to phase headers, update status.
```

### Non-script work (docs, plans, config)

```markdown
> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) — The implementation process
> - [PLANS.md](../../PLANS.md) — Plan structure and best practices
>
> **UPDATE THIS PLAN AS YOU WORK:** Mark tasks `[x]` when done, add `— DONE` to phase headers, update status.
```

## Git host

- **`origin` is GitHub**: `https://github.com/helpers-no/client-provisioning`. For PRs, issues and
  releases, use the `gh` operations in [GIT.md](GIT.md).
- **CI runs in Azure Pipelines**, and the ops team works from an Azure DevOps copy of this repo
  (`azure-pipelines.yml`, `--repository-type tfsgit`, the code wiki). So
  **[AZURE-DEVOPS.md](AZURE-DEVOPS.md) applies here even though `origin` is GitHub.** Do not delete
  it as unused. The repo-specific pipeline and wiki commands are in
  [project-azure-devops.md](project-azure-devops.md).

## Devcontainer

**Yes, [DEVCONTAINER.md](DEVCONTAINER.md) applies.** The repo uses the DevContainer Toolbox (DCT).
Generic DCT usage, such as `dev-env`, `dev-setup`, `dev-tools` and the tool inventory, is
documented on the [DCT website](https://dct.sovereignsky.no/). Repo-specific parts:

- **Auto-enabled tools**: `.devcontainer.extend/enabled-tools.conf` lists `dev-bash`,
  `dev-ai-claudecode` and `tool-azure-devops`. Add a tool id there to install it on every rebuild.
  The `dev-setup` menu also updates this file.
- **Config scripts** restore credentials from `.devcontainer.secrets/` on startup (`--verify`).
  They also accept no arguments (interactive) or `--show`:
  - `bash /opt/devcontainer-toolbox/additions/config-git.sh`: git identity
  - `bash /opt/devcontainer-toolbox/additions/config-azure-devops.sh`: Azure DevOps PAT,
    organization and project
- **Temporary installs**: `.devcontainer.extend/project-installs.sh`. There are none at present.
- **Bugs or missing tools in DCT**: DCT is a fleet agent with its own inbox. Send the finding to it
  with `~/.local/bin/urb send --to devcontainer-toolbox …`, or file it on
  [helpers-no/devcontainer-toolbox](https://github.com/helpers-no/devcontainer-toolbox/issues).
  The old `devcontainer-toolbox-issues/` draft folder was retired on 2026-09-25 (see
  `plans/completed/PLAN-adopt-fleet-template.md`).

## Contracts (non-negotiable)

- **Anything published from this repo runs with admin rights on other people's managed
  machines.** Releases are outward-facing, and a human decides.
- **Git gates** (ops-dev, 2026-09-25, urb-agents #1498):

  | | |
  |---|---|
  | **ask** | push to a shared branch, PR, merge, release/tag |
  | **ask** | any change under `scripts-win/` or `scripts-mac/`, or to a package that ships |
  | free | commits on your own feature branch, for docs and plans |

  The template's "confirm after each phase" and the fleet phase-continuation norm both yield to
  this table. Ask on the bus task when the work came from the bus, not in an interactive prompt.
- **Every script follows the standard** (above). **Validate before committing** any script change.
- **Untested is labelled untested.** Behaviour on managed Windows (Intune) or Jamf Macs that
  nobody has run is written as *vendor-documented* or *assumed*, never as established. Only Terje
  can arrange managed test machines.

## Always-loaded files

- Repo-root [`CLAUDE.md`](../../CLAUDE.md)
- Repo-root [`AGENTS.md`](../../AGENTS.md)

## URB fleet

- Agent id: `client-provisioning`
- Inbox: `~/.local/bin/urb inbox --id client-provisioning`, meaning open issues labelled
  `to:client-provisioning` in `terchris/urb-agents` (a query, not a directory)
- The client is **`~/.local/bin/urb`**. Where a template doc names `fleet-task` or
  `ops/bus/fleet-task.sh`, it is out of date: that script was deleted when the fleet moved to the
  compiled client (reported to the template maintainer on 2026-09-25). Use `urb`.
- Do not clone urb-agents. Do not copy `protocol/` here.

## Other documentation

Ops-team docs in [`docs/`](../README.md): [QUICK-START.md](../QUICK-START.md),
[OPS.md](../OPS.md), [CICD.md](../CICD.md), [QUICK-GIT.md](../QUICK-GIT.md),
[AI-SUPPORTED-DEVELOPMENT.md](../AI-SUPPORTED-DEVELOPMENT.md). Each package has its own `README.md`.
