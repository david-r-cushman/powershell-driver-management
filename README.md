# Uninstall-DisplayDrivers

[![Pester](https://github.com/david-r-cushman/powershell-driver-management/actions/workflows/pester.yml/badge.svg?branch=main)](https://github.com/david-r-cushman/powershell-driver-management/actions/workflows/pester.yml)
![Template Version](https://img.shields.io/badge/template-0.11.0-blue)

This repository contains a PowerShell script for removing display driver packages by using `devcon.exe`.

The script is designed to remain true to its original operational use case: deployment through Microsoft Configuration Manager (ConfigMgr / MECM) as a script, with explicit process exit codes that can be collected and reported by the client.

## Origin Story

This script began as a real-world operational tool created during a Windows 7 to Windows 10 in-place upgrade effort managed through Microsoft Configuration Manager.

During testing, legacy display drivers repeatedly blocked the upgrade process. Removing the display device alone was not enough, because the underlying driver package could remain in the driver store and be reinstalled after reboot. The practical problem to solve was not just device removal. It was reliable removal of the associated display driver package so the upgrade could continue successfully.

This script was created to solve that specific operational blocker without needing to know the environment-specific `oem*.inf` name ahead of time.

That history matters.

This is not a demo script and it is not an abstract exercise. It comes from an actual deployment need, and the repository is intended to preserve that practical lineage while improving maintainability, testability, and documentation over time.

## What The Script Does

`Uninstall-DisplayDrivers.ps1` uses `devcon.exe` to:

- enumerate devices in the display class
- extract matching PCI hardware IDs from the returned device list
- remove the associated driver packages for those display adapters

The script is intentionally scoped to display drivers only.

## Why `devcon.exe`

`pnputil.exe` can remove driver packages, but it generally requires you to already know the exact published driver package name, such as an `oem*.inf` file.

In this scenario, that was a major limitation. The installed display device could be identified, but the exact `oem*.inf` package name was not always known ahead of time, and simply removing the device did not guarantee that Windows would not reinstall the same driver on restart.

`devcon.exe` was a better fit because it can enumerate display devices by class and target removal by hardware ID. That made it practical to identify the active display adapters, remove the corresponding driver packages, and reduce the risk of the legacy drivers returning after reboot.

## ConfigMgr Alignment

The script is kept as a single `.ps1` file because it is intended for ConfigMgr Scripts deployment.

That design choice is deliberate:

- the script can be imported directly into the ConfigMgr console
- execution status can be interpreted through explicit exit codes
- the operational deployment shape stays close to the way the script was originally used

This repository may include tests and supporting documentation, but the deployable artifact remains a script rather than a package/program-oriented multi-file solution.

The repository preserves the script in a form that reflects its original operational shape while making it easier to review, test, and maintain over time.

## Safety And Guardrails

The script includes several intentional guardrails:

- it requires an elevated administrative context
- it blocks execution on known virtual machine platforms
- it verifies that `devcon.exe` is present before attempting removal
- it supports `-WhatIf` through `ShouldProcess`

These checks are meant to make the script safer to review, test, and deploy.

## Exit Codes

The script exits with explicit codes so ConfigMgr can report outcomes more accurately:

- `0` = Success
- `1` = General failure
- `2` = Dependency missing (`devcon.exe` not found)
- `3` = Virtual machine detected
- `4` = `devcon.exe listclass display` failed
- `5` = Administrative context required

## Validation Status

Pester test status is surfaced at the top of this README through the GitHub Actions badge.

That badge reflects the current result of the repository's automated Pester workflow on the `main` branch, giving a quick signal about whether the script's tested behavior is currently passing in CI.

## Project Versioning

This repository versions the PowerShell driver management project itself using Semantic Versioning.

- Current project version: see [`VERSION`](VERSION)
- Version history: see [`CHANGELOG.md`](CHANGELOG.md)

The project version is separate from the template-version badge at the top of this README. The badge records the `pwsh-dev-template` guidance version used for synced AI guidance and guardrails.

For a design-focused map of how the script is structured internally, see [`docs/script-architecture-overview.md`](docs/script-architecture-overview.md).
## Repository Layout

- `src/Public/Uninstall-DisplayDrivers.ps1`
  The deployable script.
- `Tests/Unit/Uninstall-DisplayDrivers.Tests.ps1`
  Pester tests for the script logic.
- `docs/`
  Supporting notes and repository-level guidance.

## Testability Approach

Although the deployment target is a single ConfigMgr-importable script, the script has been structured internally with helper functions so it can still be tested with Pester.

One intentional design choice was replacing a parse-time `#Requires -RunAsAdministrator` guard with a runtime administrative-context check. That keeps the operational requirement in place while also allowing non-elevated test sessions to validate the script's behavior safely.

The automated Pester tests validate script logic by mocking `devcon.exe` interactions rather than invoking the real executable. That means CI can run without `devcon.exe` being present in the repository, while production use still requires the real `devcon.exe` file to be present beside the script at runtime.

That balance is important here: the script remains faithful to its deployment origins, but it is no longer locked into a form that is difficult to validate safely.

## Usage Notes

Before using the script:

- run it in an elevated context
- ensure `devcon.exe` is available in the same directory as the script
- use `-WhatIf` first if you want to validate intended behavior before removal

Example:

```powershell
.\Uninstall-DisplayDrivers.ps1 -WhatIf
```

## References

- [DevCon overview](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devcon)
- [DevCon listclass](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devcon-listclass)
- [DevCon remove](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devcon-remove)
- [Create and run PowerShell scripts from the Configuration Manager console](https://learn.microsoft.com/en-us/intune/configmgr/apps/deploy-use/create-deploy-scripts)
