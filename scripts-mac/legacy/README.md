# Legacy Mac packages

Kept for reference, **not maintained, and not deployed.**

| Package | Retired | Replaced by | Why |
|---|---|---|---|
| [`rancher-desktop/`](rancher-desktop/) | 2026-09-25 | Jamf's native Rancher Desktop install with the deployment profile in [`../rancher-desktop-jamf/`](../rancher-desktop-jamf/) | Jamf installs Rancher Desktop itself now. Our config and Kubernetes scripts wrote the same `/Library/Managed Preferences` files that Jamf now manages, so keeping them live would fight Jamf. Decided by Terje (urb-agents #1516, #1519). |

The scripts still pass validation (`bash docs/ai-developer/tools/validate-bash.sh legacy/rancher-desktop`). The default run no longer includes them. They are pinned to Rancher Desktop **1.22.0** and write a settings **version 10** profile: do not use them for 1.24.
