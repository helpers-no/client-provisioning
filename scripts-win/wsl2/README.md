# WSL2 Intune Deployment Package

Enables the two Windows features required for WSL2:

- `Microsoft-Windows-Subsystem-Linux`
- `VirtualMachinePlatform`

These are prerequisites for Rancher Desktop on Windows.

**Requires Windows 11 (build 22000+) on an x64 PC.** WSL2 itself runs on Windows 10 2004+, but this package prepares the PC for Rancher Desktop 1.24, which needs Windows 11 and is x64-only. `install.ps1` stops with a plain message otherwise (ERR002 build, ERR008 architecture).

The check logic has a unit test that runs anywhere `pwsh` runs, with no Windows needed: `pwsh scripts-win/wsl2/tests/test-platform-check.ps1`.

## Scripts

| Script | Purpose |
|--------|---------|
| `install.ps1` | Enables both features via DISM, exits 3010 for reboot |
| `detect.ps1` | Tells Intune whether WSL2 features are already enabled |
| `build.ps1` | Creates the `.intunewin` package (runs in devcontainer) |

## How it works

WSL2 is not an app install. There is no installer, MSI, or EXE. The install script runs two DISM commands to enable Windows features, then exits with code 3010 to request a reboot.

The standard `wsl --install` command does not work in Intune's SYSTEM context ([GitHub WSL #11142](https://github.com/microsoft/WSL/issues/11142)). We use DISM instead.

## Intune configuration

See [INTUNE.md](INTUNE.md) for portal settings.

## Testing

See [tests/](tests/) for USB test scripts. Testing requires two sessions on the Windows PC (pre-reboot and post-reboot).
