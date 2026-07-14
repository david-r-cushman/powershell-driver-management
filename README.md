# Uninstall-DisplayDrivers

[![CI](https://github.com/david-r-cushman/powershell-driver-management/actions/workflows/pester.yml/badge.svg?branch=main)](https://github.com/david-r-cushman/powershell-driver-management/actions/workflows/pester.yml)

<!-- BEGIN generated:readme-powershell-badge -->
![PowerShell 7.4](https://img.shields.io/badge/PowerShell-7.4-blue)
<!-- END generated:readme-powershell-badge -->
![Template Version](https://img.shields.io/badge/template-0.15.0-blue)

This repository contains a PowerShell script for removing display driver packages by using `devcon.exe`.

The script is designed to remain true to its original operational use case: deployment through Microsoft Configuration Manager (ConfigMgr / MECM) as a script, with explicit process exit codes that can be collected and reported by the client.

It grew out of a Windows 7 to Windows 10 in-place upgrade effort where legacy display drivers repeatedly blocked the upgrade path. The practical problem was not just removing a display device. It was reliably removing the associated driver package without needing to know the environment-specific `oem*.inf` name ahead of time.

<!-- BEGIN generated:readme-runtime-focus -->
- PowerShell 7.4 development
<!-- END generated:readme-runtime-focus -->

Quick navigation:

- [Portfolio Context](#portfolio-context)
- [Engineering Principles in Practice](#engineering-principles-in-practice)
- [Validation And Maintenance](#validation-and-maintenance)
- [Repository Structure](#repository-structure)

## Portfolio Context

This repository is part of a PowerShell portfolio built from `pwsh-dev-template`, and it is anchored in a real deployment problem rather than a generic sample. It demonstrates how to preserve the operational shape of a ConfigMgr-delivered script while still improving readability, testability, and long-term maintainability.

A reviewer should pay attention first to the script's practical lineage, its deployment-aware safety model, and how the repo keeps a single-file operational artifact compatible with clearer structure, explicit exit behavior, and test-focused internal organization. It is not a demo script or an abstract exercise; it comes from an actual deployment blocker and is intended to preserve that lineage while improving maintainability over time.

## Engineering Principles in Practice

<!-- BEGIN generated:readme-runtime-philosophy -->
- **Deterministic Base Runtime:** The development container is built from a pinned PowerShell 7.4 on Ubuntu 22.04 base image to reduce environmental drift
<!-- END generated:readme-runtime-philosophy -->
- **ConfigMgr-Compatible Delivery Shape:** The repository preserves a single-script artifact that can still be imported and executed through ConfigMgr Scripts without forcing an artificial package-first redesign
- **Practical Tool Selection:** `devcon.exe` is used because the problem is hardware-ID-driven driver removal, not merely uninstalling a known `oem*.inf` package by name
- **Safe Driver Removal:** Elevated-context checks, virtualization guards, dependency verification, and `ShouldProcess` support are treated as integral behavior, not optional polish
- **Explicit Result Signaling:** Exit codes remain part of the interface so ConfigMgr and operators can distinguish operational outcomes cleanly
- **Testable Single-Script Design:** Internal helper structure supports Pester validation without changing the deployable artifact into a multi-file operational unit

For the deeper operating model behind that approach, see [`docs/powershell-ai-operating-model.md`](docs/powershell-ai-operating-model.md). For repository-specific structure and script design notes, see [`docs/script-architecture-overview.md`](docs/script-architecture-overview.md).

## Use This Repository

1. Read the origin and ConfigMgr sections below first so the deployment shape and operational constraints stay clear.
2. Review the safety checks and explicit exit-code behavior before making changes to execution flow.
3. Use `-WhatIf` when validating removal intent before running the script in a real environment.
4. Use the Pester tests and repo checks to validate changes without requiring `devcon.exe` in CI.
5. Refer to `Usage Notes`, `Exit Codes`, and the script-architecture overview for the practical execution and maintenance path.

## Runtime And Environment

<!-- BEGIN generated:readme-runtime-stack -->
- **Runtime:** PowerShell 7.4.x (LTS) on Ubuntu 22.04
<!-- END generated:readme-runtime-stack -->
- **Execution Target:** The real operational target is Windows because the script removes Windows display driver packages through `devcon.exe`
- **Deployment Shape:** The deployable artifact remains a single `.ps1` file suitable for ConfigMgr Scripts deployment
- **Development Modes:** Local VS Code, Docker Dev Containers, and GitHub Codespaces
- **Isolation Strategy:** Use the container to reduce host tooling and credential exposure during development work

## Tooling

<!-- BEGIN generated:readme-tooling-list -->
- **Pester 6.0.0:** For unit and integration testing
- **PSScriptAnalyzer 1.25.0:** To enforce PowerShell best practices and security rules
- **Azure CLI:** Pre-installed for cloud resource management
- **PSReadLine 2.4.5:** Configured for a more efficient terminal experience
<!-- END generated:readme-tooling-list -->

The automated Pester workflow is surfaced through the badge at the top of this README and validates the script through mocked `devcon.exe` interactions rather than real device changes.

## Repository Structure

- `src/Public/Uninstall-DisplayDrivers.ps1`: the deployable script artifact
- `Tests/Unit/Uninstall-DisplayDrivers.Tests.ps1`: Pester coverage for script logic and behavior contracts
- `docs/`: architecture notes, operating-model guidance, and supporting documentation
- `scripts/`: validation, sync, cleanup, and README workflow entrypoints delivered from the template baseline

## Validation And Maintenance

Run the standard repository checks before committing meaningful changes:

```powershell
pwsh -NoProfile -File ./scripts/Invoke-RepoChecks.ps1
```

If this repository keeps the template-managed generated Markdown blocks, refresh or validate them through:

```powershell
pwsh -NoProfile -File ./scripts/Update-GeneratedMarkdown.ps1 -Check
```

## Downstream Guidance Sync

Use `.codex/skills/downstream-guidance-sync/SKILL.md` with `scripts/Invoke-TemplateGuidanceSync.ps1` when you want to adopt newer `pwsh-dev-template` guidance or README workflow assets without overwriting repository-owned implementation.

## Prerequisites And Setup

- Install PowerShell 7.4 or use the repository Dev Container / Codespace baseline for development work.
- Run the script in an elevated context when executing it for real driver removal.
- Ensure `devcon.exe` is present in the same directory as the deployable script before runtime use.
- Use `-WhatIf` first when validating intended behavior before actual removal.
- Review `docs/agent-workflows.md`, `AGENTS.md`, and `.github/copilot-instructions.md` before using agent-driven repository changes.

## Template Versioning

This repository versions the PowerShell driver management project itself using Semantic Versioning.

- Current project version: see [`VERSION`](VERSION)
- Version history: see [`CHANGELOG.md`](CHANGELOG.md)

The project version is separate from the template-version badge at the top of this README. That badge records the synced `pwsh-dev-template` guidance and workflow baseline used by this repository.

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

Validation status is surfaced at the top of this README through the GitHub Actions badge.

That badge reflects the current result of the repository's automated CI workflow on the `main` branch, including repo checks and unit-test validation for the script's current behavior.

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
