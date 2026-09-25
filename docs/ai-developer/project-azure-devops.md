# project-azure-devops — this repo's Azure DevOps specifics

Generic `az` usage, PRs, merging and safety rules are in [AZURE-DEVOPS.md](AZURE-DEVOPS.md). This
file keeps what is specific to **client-provisioning**. It was moved here from the retired
`GIT-HOSTING-AZURE-DEVOPS.md` on 2026-09-25.

**Why this applies although `origin` is GitHub:** the ops team works from an Azure DevOps copy of
this repo, CI runs in Azure Pipelines, and `docs/` is published as the Azure DevOps code wiki. See
[project-client-provisioning.md](project-client-provisioning.md#git-host).

---

## Authentication in the devcontainer

The DCT config script sets the PAT, organization and project defaults. It stores them in
`.devcontainer.secrets/`, so they survive rebuilds:

```bash
bash /opt/devcontainer-toolbox/additions/config-azure-devops.sh          # interactive
bash /opt/devcontainer-toolbox/additions/config-azure-devops.sh --show   # current config
```

The same PAT works for `az devops` commands and for `git clone`/`git push`. Creating the PAT is a
human step, as [AZURE-DEVOPS.md](AZURE-DEVOPS.md) explains.

---

## Pipeline: Build Intune Packages

How the pipeline works and where the artifacts land: [CICD.md](../CICD.md).

```bash
# Create the pipeline from YAML (one-time)
az pipelines create \
  --name "Build Intune Packages" \
  --repository client-provisioning \
  --repository-type tfsgit \
  --branch main \
  --yml-path azure-pipelines.yml \
  --skip-first-run true

az pipelines list -o table
az pipelines run list --pipeline-id <ID> -o table
az pipelines run show --id <RUN_ID> \
  --query "{status: status, result: result, startTime: startTime, finishTime: finishTime}" -o table

# Manual run: this builds packages that ship. Ask first.
az pipelines run --id <PIPELINE_ID> --branch main

# Artifacts: one per package (for example rancher-desktop), plus drop for logs
az pipelines runs artifact list --run-id <RUN_ID> -o table
az pipelines runs artifact download --run-id <RUN_ID> --artifact-name rancher-desktop --path ./downloads
az pipelines runs artifact download --run-id <RUN_ID> --artifact-name drop --path ./logs
```

---

## Wiki: `docs/` published as a code wiki

Azure DevOps publishes a folder from the repo directly as a wiki. When you push changes under
`docs/`, the wiki updates. Each repo in the project publishes its own `docs/` as a separate code
wiki, and all of them appear in the wiki dropdown.

```bash
az devops wiki create --name "WIKI_NAME" --type codewiki \
  --repository REPO_NAME --mapped-path /docs --version main
az devops wiki list -o table
az devops wiki delete --wiki WIKI_NAME     # outward-facing, ask first
```

How the wiki maps to the repo:

- **Folder structure = wiki structure.** Subfolders become sections, and markdown files become pages.
- **`README.md`** in a folder is the landing page for that section.
- **`.order`** sets the page order within a folder: one filename per line, without `.md`.
  **When you add, rename or delete a doc, update the `.order` in its folder**
  (`docs/.order`, `docs/ai-developer/.order`).
- **One folder per wiki.** Each `az devops wiki create` publishes one path from one repo.
