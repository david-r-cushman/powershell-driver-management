# Environment Setup: PowerShell 7.4 Template

## Overview

This repository provides a reusable PowerShell development baseline that can be used locally in VS Code, in a Docker Dev Container, or in GitHub Codespaces.

The goal of the environment is to improve consistency, reduce unnecessary host-tooling drift, and make it easier to start new PowerShell Core projects with a ready-to-use structure and toolchain.

## Development Modes

- **Local VS Code:** Work directly from the host editor with the repository's recommended extensions and settings.
- **Dev Container:** Reopen the repository in a containerized Linux development environment.
- **GitHub Codespaces:** Use the same repository structure in a browser-accessible hosted environment.

## Technical Stack

- **Runtime:** PowerShell 7.4.x (LTS) on Ubuntu 22.04
- **Local Container Runtime:** Docker Desktop via WSL 2 backend
- **Editor Support:** VS Code settings, launch configuration, and extension recommendations
- **Tooling:** Azure CLI, Pester, PSScriptAnalyzer, and PSReadLine
- **Governance:** `.editorconfig`, Markdown linting, and repository Copilot instructions

## Prerequisites For Local Container Use

Before opening this project in a local Dev Container, ensure the host machine is configured as follows:

1. **WSL 2:** Installed and updated with `wsl --update`
2. **Docker Desktop:** Configured to use the WSL 2 engine
3. **VS Code:** Installed with the Dev Containers extension

Recommended supporting extensions include:

- `ms-vscode.PowerShell`
- `ms-vscode.editorconfig`
- `ms-azuretools.vscode-docker`
- `ms-vscode.azurecli`
- `DavidAnson.vscode-markdownlint`

## Getting Started

### Local Dev Container

When you open this folder in VS Code, you should be prompted to reopen the repository in a Dev Container.

That flow:

- builds the Dockerfile-based development image
- installs the baseline PowerShell tooling inside the container
- starts an interactive PowerShell environment with the configured profile

### GitHub Codespaces

If you are using GitHub Codespaces instead, create a Codespace from a repository generated from this template and open the project in the browser-based editor.

## PowerShell Profile Behavior

The container environment includes a global PowerShell profile located at `/opt/microsoft/powershell/7/Microsoft.PowerShell_profile.ps1`.

That profile:

- imports `PSReadLine`
- enables history-based prediction
- enables ListView completion
- displays a startup message confirming the template environment has loaded

## Design Principles

- **Controlled Base Runtime:** The container starts from a pinned PowerShell 7.4 on Ubuntu 22.04 base image
- **Consistent Tooling Baseline:** Core tools are installed automatically so new repositories begin from a predictable starting point, even though not every tool is version-pinned
- **Cross-Platform Formatting:** LF line endings and editor settings are used to reduce host and container formatting drift
- **Credential Boundary Awareness:** Development containers are intended to avoid pulling host-resident GitHub Copilot authentication state into the container environment

## Troubleshooting

- **Module Not Found:** Rebuild the container without cache to force a clean environment refresh
- **Line Ending Errors:** Verify `git config core.autocrlf` is set to `input` or `false`
- **Identity Issues:** Run `az login` inside the container or Codespaces terminal to authenticate that environment
