# Plan: Adopt the fleet ai-developer template, and add AGENTS.md

Bring docs/ai-developer/ up to the fleet ai-developer-template and add a root AGENTS.md, keeping this repo's own script standard.

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) — The implementation process
> - [PLANS.md](../../PLANS.md) — Plan structure and best practices
>
> **UPDATE THIS PLAN AS YOU WORK:** Mark tasks `[x]` when done, add `— DONE` to phase headers, update status.

## Status: Active

**Goal**: Bring `docs/ai-developer/` up to the fleet `ai-developer-template` (terchris/urb-agents) and
give the repo a root `AGENTS.md`, without flattening this repo's own script standard. Land the
one-script-install investigation handed over by devcontainer-toolbox.

**Source**: urb-agents #1498 (from ops-dev). Decisions settled on that task on 2026-09-25 — see
[Decisions](#decisions-settled-on-1498).

**Worked example**: helpers-no/devcontainer-toolbox PR #100 (released as 1.8.1) did the same job.

**Last Updated**: 2026-09-25

---

## Problem Summary

`docs/ai-developer/` predates the fleet template. It has its own `README.md`, `WORKFLOW.md` and
`PLANS.md`, older copies of two portable docs under other names (`DEVCONTAINER-TOOLBOX.md`,
`GIT-HOSTING-AZURE-DEVOPS.md`), a folder of drafts about another agent's repo
(`devcontainer-toolbox-issues/`), and no `project-*.md`. There is no root `AGENTS.md`.

The local `README.md` is also out of date: it describes a bash-only, macOS-only repo, but the repo
has `scripts-win/`, `rules/powershell.md`, the PowerShell validator and the Azure Pipelines
`.intunewin` build.

---

## Decisions (settled on #1498)

1. **Write this PLAN first**, then implement on a feature branch.
2. **`devcontainer-toolbox-issues/`: delete it.** All 11 drafts correspond to issues #42–#60 on
   `helpers-no/devcontainer-toolbox`, and ops-dev verified on 2026-09-25 that **every one is
   closed; none are open in that range.** Nothing is re-filed to the bus. Phase 3 re-checks this
   before deleting and records the draft-to-issue mapping here.
3. **Old docs: replace them with the template names.** Repo-specific content moves into
   `project-client-provisioning.md`, and the references to the old names are fixed.
4. **Where the template and the local standard overlap:** the local standard wins on script
   content (`rules/`, `tools/`, `templates/`, `docs/SCRIPT-STANDARDS.md`, USB test procedures,
   `docs/MANUAL-TEST-WINDOWS-REINSTALL.md`). The template wins on process (plans, handovers,
   the AGENTS.md entry point). Where they truly conflict, this plan diverges on purpose and says why.

---

## What is adopted, kept, and deliberately not adopted

| Item | Action | Note |
|---|---|---|
| `README.md`, `WORKFLOW.md`, `PLANS.md` | Replace with template | Repo-specific content moves to `project-client-provisioning.md` (see Phase 2) |
| `GIT.md`, `COORDINATION.md`, `VERIFICATION.md`, `WORKTREE.md`, `SECURITY.md` | Add from template | `SECURITY.md` keeps the template body. There is no published site, so there is no site gate |
| `DEVCONTAINER-TOOLBOX.md` | Replace with template `DEVCONTAINER.md` | The repo has a DCT devcontainer, so the project doc says it applies |
| `GIT-HOSTING-AZURE-DEVOPS.md` | Replace with template `AZURE-DEVOPS.md` | **Kept even though `origin` is GitHub.** CI runs in Azure Pipelines (`azure-pipelines.yml`), and the ops-team docs (`docs/QUICK-GIT.md`, `QUICK-START.md`) describe an Azure DevOps copy. The project doc explains this |
| `project.EXAMPLE.md` | Becomes `project-client-provisioning.md` | Filled from what the repo actually is |
| `plans/backlog/1PRIORITY.md`, `index.md`, `active/README.md`, `completed/README.md` | Add | Existing plan files are not moved or edited |
| `rules/`, `tools/`, `templates/` | **Keep unchanged** | This is the local script standard |
| `devcontainer-toolbox-issues/` | Delete | Decision 2 |
| `_category_.json` | **Not adopted** | Only for Docusaurus, and this repo has no site |
| Root `CLAUDE.md` | Keep its four key rules, add the template's Start Here | The key rules are this repo's contract |
| Root `AGENTS.md` | Add | From template, placeholders filled |

### Deliberate divergences and template defects to report

These go to the template maintainer as a bus item (Phase 6), not just into this file:

- **Template `AGENTS.md` / `CLAUDE.md` links point at `../docs/ops-host/`**, which is left over from
  another repo. Fixed here to point at `docs/ai-developer/`.
- **Template `CLAUDE.md` says `fleet-task inbox --id`, but `AGENTS.md` and `README.md` say
  `~/.local/bin/urb inbox --id`.** This repo uses `urb`.
- **Template `README.md` says "Ask user to confirm after each phase".** The fleet phase-continuation
  norm (ops, 23/8) says to proceed through phases of an approved plan. For this repo the stricter
  local rule stays: **ask before every git write**, because releases run with admin rights on
  managed machines. The project doc states which rule applies to what.
- **Template `WORKFLOW.md` has no version-bump step.** This repo's `SCRIPT_VER` rule moves to the
  project doc, as DCT did with its own version rule.

---

## Phase 1: Branch and template copy — DONE

### Tasks

- [x] 1.1 Ask for approval (on #1498), then create branch `feature/adopt-fleet-template`
- [x] 1.2 Move this plan to `plans/active/`
- [x] 1.3 Fetch a fresh copy of `ai-developer-template/` from urb-agents through `gh api` (Contents API, no clone)
- [x] 1.4 Add `GIT.md`, `COORDINATION.md`, `VERIFICATION.md`, `WORKTREE.md`, `SECURITY.md` unchanged

### Validation

The files are identical to the template (`diff` against the fetched copy).

---

## Phase 2: project doc, then replace README / WORKFLOW / PLANS — DONE

### Tasks

- [x] 2.1 Write `project-client-provisioning.md` covering: what the repo is (host installers for
      managed Windows via Intune and macOS via Jamf); layout (`scripts-mac/`, `scripts-win/`,
      `docs/`, `.azure-pipelines/`); a current package table for **both** platforms; validation
      and version commands for bash **and** PowerShell; the templates; git host (GitHub `origin`,
      Azure Pipelines CI, Azure DevOps ops-team copy); devcontainer = yes (DCT); links to
      `docs/SCRIPT-STANDARDS.md`, `docs/MANUAL-TEST-WINDOWS-REINSTALL.md`, `docs/CICD.md`,
      `docs/OPS.md`; URB agent id and inbox
- [x] 2.2 Contracts section: **anything published runs with admin rights on other people's managed
      machines**, so releases are outward-facing and a human decides. Ask before any git
      add / commit / push / branch / merge. Every script follows `rules/`. Validate before committing
- [x] 2.3 Move content out of the old files so nothing is lost: the IMPLEMENTATION RULES blocks
      (bash, **and a new PowerShell block**, plus non-script), the three-layer script-standard
      description, and the `SCRIPT_VER` version-management rule from old `WORKFLOW.md`
- [x] 2.4 Replace `README.md`, `WORKFLOW.md`, `PLANS.md` with the template versions. Change only
      what has to change (for example the `project.EXAMPLE.md` link)
- [x] 2.5 Replace `DEVCONTAINER-TOOLBOX.md` → `DEVCONTAINER.md` and
      `GIT-HOSTING-AZURE-DEVOPS.md` → `AZURE-DEVOPS.md` (`git mv`, then the template content).
      Before overwriting, diff the old files and move any repo-specific lines into the project doc

### Validation

Every section of the old README/WORKFLOW exists either in a template doc or in the project doc
(checklist in Implementation Notes).

---

## Phase 3: References, root files, cleanup — DONE

### Tasks

- [x] 3.1 Fix references to the old names: `docs/README.md:46`, `docs/QUICK-GIT.md:97`,
      `docs/QUICK-START.md:165,228,229`, `docs/AI-SUPPORTED-DEVELOPMENT.md:9,129,130`. Completed
      plans are history and are **not** rewritten
- [x] 3.2 Add root `AGENTS.md`. Update root `CLAUDE.md`: keep the four key rules, add Start Here
      pointing at `project-client-provisioning.md`, and add the fleet-bus paragraph (urb, no file bus)
- [x] 3.3 Re-check that issues #42–#60 on helpers-no/devcontainer-toolbox are all closed, record the
      draft → issue mapping below, then `git rm -r docs/ai-developer/devcontainer-toolbox-issues/`

### Validation

`grep -rn 'GIT-HOSTING-AZURE-DEVOPS\|DEVCONTAINER-TOOLBOX.md\|devcontainer-toolbox-issues'`
returns only hits in `plans/completed/` and in this plan.

---

## Phase 4: Plans folder, and land the handover investigation — DONE

### Tasks

- [x] 4.1 Add `plans/active/README.md`, `plans/completed/README.md`, `plans/backlog/index.md`
      (rows: `INVESTIGATE-wsl-intune.md`, `INVESTIGATE-windows-one-script-install.md`) and
      `plans/backlog/1PRIORITY.md`, true as of the day this lands
- [x] 4.2 Land `plans/backlog/INVESTIGATE-windows-one-script-install.md` **from the comment on
      #1492** (fetched fresh, not from any copy). Fix the IMPLEMENTATION RULES links to
      `../../WORKFLOW.md` / `../../PLANS.md`. Do not edit the author's text beyond that
- [x] 4.3 Add a clearly marked **"Untested claims"** section at the top of the landed file. It lists
      every statement about managed Windows 11 + Intune and Jamf Macs that nobody has run: for
      example the winget Intune block, `wsl --install --no-distribution` behaviour, restart codes,
      Admin on Demand elevation, and the Rancher Desktop 1.24 Windows-11-only finding. Mark each
      one *vendor-documented* or *assumed*, and say that only Terje can arrange the test machines
- [x] 4.4 Note in both investigations how they overlap with `INVESTIGATE-wsl-intune.md`

### Validation

The landed file matches the #1492 comment except for the rules links and the added section (`diff`).

---

## Phase 5: Validate

### Tasks

- [ ] 5.1 `bash docs/ai-developer/tools/validate-bash.sh` and `bash docs/ai-developer/tools/validate-powershell.sh`
      pass. No scripts change, so this proves nothing broke
- [ ] 5.2 Check relative links: a scratch script checks that every relative `.md` link under
      `docs/`, `CLAUDE.md` and `AGENTS.md` resolves (there is no Docusaurus build to rely on)
- [ ] 5.3 No `SCRIPT_VER` bump, because no script changes. The repo has no `version.txt`

### Validation

Both validators exit 0, and the link check reports zero broken links.

---

## Phase 6: Report and hand back

### Tasks

- [ ] 6.1 Move this plan to `completed/`
- [ ] 6.2 **Ask on #1498** before push / PR / merge. The PR description lists what was adopted,
      what was not, and why
- [ ] 6.3 Report on #1498: what was adopted, what was deliberately not, and which claims in the
      landed investigation are untested
- [ ] 6.4 Send the template defects above to the template maintainer via `urb send`
- [ ] 6.5 Refresh fleet status with `urb publish-status --via-bus` (plan counts and next step change)

---

## Acceptance Criteria

- [ ] Root `AGENTS.md` exists, and root `CLAUDE.md` points at `project-client-provisioning.md`
- [ ] `docs/ai-developer/` has every required template file except `_category_.json`, which is deliberately skipped
- [ ] `rules/`, `tools/` and `templates/` are unchanged, and no content from the old README/WORKFLOW is lost
- [ ] `devcontainer-toolbox-issues/` is gone, and this plan records the evidence
- [ ] `INVESTIGATE-windows-one-script-install.md` is landed with an explicit untested-claims section
- [ ] Both validators pass, and there are zero broken relative links
- [ ] A human approved every git write

---

## Implementation Notes

**Old content → new home checklist** (fill during Phase 2):

| Old location | Content | New home |
|---|---|---|
| README "Three layers" | script-standard layering | project doc |
| README "IMPLEMENTATION RULES" | copy-in blocks | project doc (+ PowerShell block) |
| README "This Project" / packages / validation / templates | repo facts | project doc (updated for `scripts-win/`) |
| WORKFLOW "Version Management" | `SCRIPT_VER` bump rule | project doc |
| WORKFLOW flow / feature branch | generic process | template `WORKFLOW.md` |
| README "Folder Structure" | tree | dropped: the template README and project doc Layout cover it |
| README "Devcontainer toolbox" pointer | link | project doc, Devcontainer |
| DEVCONTAINER-TOOLBOX config scripts, `enabled-tools.conf`, `project-installs.sh` | repo-specific DCT setup | project doc, Devcontainer |
| DEVCONTAINER-TOOLBOX "Reporting Bugs" (write into `devcontainer-toolbox-issues/`) | superseded | project doc: `urb send --to devcontainer-toolbox` or a GitHub issue |
| DEVCONTAINER-TOOLBOX quick commands, `dev-tools` JSON queries, tool registry | generic DCT usage | dropped: covered by template `DEVCONTAINER.md` and the DCT website |
| GIT-HOSTING-AZURE-DEVOPS auth via `config-azure-devops.sh` | repo-specific | new `project-azure-devops.md` |
| GIT-HOSTING-AZURE-DEVOPS pipeline create/runs/artifacts ("Build Intune Packages") | repo-specific | `project-azure-devops.md` |
| GIT-HOSTING-AZURE-DEVOPS wiki publishing and `.order` | repo-specific | `project-azure-devops.md` |
| GIT-HOSTING-AZURE-DEVOPS PRs, merge, repos, boards, GitHub-vs-az table | generic `az` | template `AZURE-DEVOPS.md` |
| `docs/ai-developer/.order` (wiki page order) | old names | rewritten for the new file names |

**Divergence found while implementing:** a second project file, `project-azure-devops.md`, keeps the
repo-specific pipeline and wiki commands out of the main project doc. The template README says to
read *all* `project-*.md` files, so this is within the convention.

**Template frontmatter:** the template docs start with `mdx: format: md` YAML frontmatter, which is
meant for Docusaurus. Azure DevOps wiki shows frontmatter as a table at the top of the page. This is
cosmetic, and the files stay identical to the template, so the template can be synced later.

**devcontainer-toolbox-issues/ → issue mapping.** Re-checked on 2026-09-25 with `gh issue view` on
helpers-no/devcontainer-toolbox #42–#60: every issue is CLOSED, and the PRs in that range are MERGED.
Nothing was re-filed to the bus. All 11 drafts plus the folder README were deleted.

| Draft | Issue | State |
|---|---|---|
| ISSUE-azure-devops-cli.md | #42 | closed |
| ISSUE-machine-readable-tool-inventory.md | #43 | closed |
| ISSUE-config-azure-devops.md | #44 | closed |
| ISSUE-persist-claude-credentials.md | #46 | closed (fix PR #52 merged) |
| ISSUE-lightweight-powershell.md | #47 | closed (PR #53 merged) |
| ISSUE-azure-devops-pat-env.md | #48 | closed (PR #50 merged) |
| ISSUE-vscode-devcontainers-extension.md | #49 | closed (PR #51 merged) |
| ISSUE-update-upgrade-mechanism.md | #54 (see also #45) | closed (PR #56 merged) |
| ISSUE-claude-credential-sync-migration-and-api-key.md | #58 | closed |
| ISSUE-persist-github-cli-credentials.md | #59 | closed |
| ISSUE-cmd-publish-github.md | #60 | closed |

## Files to Modify

- New: `AGENTS.md`, `docs/ai-developer/{GIT,COORDINATION,VERIFICATION,WORKTREE,SECURITY}.md`,
  `docs/ai-developer/project-client-provisioning.md`, `docs/ai-developer/project-azure-devops.md`, `plans/{active,completed}/README.md`,
  `plans/backlog/{1PRIORITY,index,INVESTIGATE-windows-one-script-install}.md`
- Replaced: `docs/ai-developer/{README,WORKFLOW,PLANS}.md`
- Renamed: `DEVCONTAINER-TOOLBOX.md` → `DEVCONTAINER.md`, `GIT-HOSTING-AZURE-DEVOPS.md` → `AZURE-DEVOPS.md`
- Edited: `docs/ai-developer/.order`, `CLAUDE.md`, `docs/README.md`, `docs/QUICK-GIT.md`, `docs/QUICK-START.md`, `docs/AI-SUPPORTED-DEVELOPMENT.md`
- Deleted: `docs/ai-developer/devcontainer-toolbox-issues/` (12 files)
