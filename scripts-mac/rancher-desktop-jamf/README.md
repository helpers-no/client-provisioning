# Rancher Desktop on Jamf-managed Macs: deployment profile

Jamf installs Rancher Desktop itself. This folder holds the **deployment profile** the Jamf manager applies. It is the same file Terje gave the Jamf manager on 2026-09-25 (urb-agents #1516). The old install scripts are in [`../legacy/rancher-desktop/`](../legacy/rancher-desktop/).

## The profile

[`io.rancherdesktop.profile.defaults.plist`](io.rancherdesktop.profile.defaults.plist):

| Key | Value | Why |
|---|---|---|
| `version` | `19` | `CURRENT_SETTINGS_VERSION` in Rancher Desktop v1.24.0 (`pkg/rancher-desktop/config/settings.ts:9`). A profile **without** `version` is rejected with an error dialog. An older number is migrated |
| `containerEngine.name` | `moby` | Required by the devcontainer toolbox (Docker API) |
| `kubernetes.enabled` | `false` | The 1.24 default is **`true`**, so "off" must be set explicitly |

**Not in the profile, on purpose:**
- **Memory:** Rancher computes it itself, as 25 % of RAM capped at 6 GB (`settingsImpl.ts`, `getDefaultMemory()`).
- **CPUs:** a fixed default of 2.

## How to apply it in Jamf

- Configuration Profile → **Application & Custom Settings**.
- Preference domain: **`io.rancherdesktop.profile.defaults`**; upload this file.
- macOS writes it to `/Library/Managed Preferences/`. Rancher Desktop looks there first (`src/go/rdctl/pkg/paths/paths_darwin.go`), and the first directory with a profile wins.

## Behaviour to know

- **Defaults apply only on the first launch**, when no settings file exists yet. On a Mac where Rancher has already been started, this profile changes nothing.
- These are **defaults, not locked** values: users can change them later. UIS users need to turn on Kubernetes and give Rancher more memory themselves.
- With a profile present, Rancher skips its first-run dialog.

## Tested?

**No.** The values are read from the Rancher Desktop v1.24.0 source, and the file passes `plutil -lint`. Applying it through Jamf on a Mac where Rancher has never been started has not been tried; no such Mac is available (urb-agents #1510).
