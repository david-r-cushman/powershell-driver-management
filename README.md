# Uninstall-DisplayDrivers

This repository contains a PowerShell script for removing display driver packages by using `devcon.exe`.

The script is designed to remain true to its original operational use case: deployment through Microsoft Configuration Manager (ConfigMgr / MECM) as a script, with explicit process exit codes that can be collected and reported by the client.

## Origin Story

This script began as a real-world operational tool created to solve a specific problem in managed Windows environments: reliably removing display drivers without needing to know the environment-specific `oem*.inf` name ahead of time.

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

`devcon.exe` is a better fit for this scenario because it can enumerate display devices by class and target removal by hardware ID. That makes the script more practical in environments where the installed driver package name is not known in advance.

## ConfigMgr Alignment

The script is kept as a single `.ps1` file because it is intended for ConfigMgr Scripts deployment.

That design choice is deliberate:

- the script can be imported directly into the ConfigMgr console
- execution status can be interpreted through explicit exit codes
- the operational deployment shape stays close to the way the script was originally used

This repository may include tests and supporting documentation, but the deployable artifact remains a script rather than a package/program-oriented multi-file solution.

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
