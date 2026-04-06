# PowerShell 7.4 Template: Available Anywhere

This repository is a GitHub template that provides a baseline development environment for new PowerShell projects.

It is intended to give new repositories a consistent starting point for:

- PowerShell 7.4 development
- local VS Code development
- Docker Dev Container development
- GitHub Codespaces development
- formatting and linting standards
- Pester-based testing structure
- secure-by-default development habits

Project-specific scripts, modules, tests, and automation are expected to be added in repositories created from this template.

The template is designed to support both script-based and module-oriented PowerShell Core projects, with built-in structure for testing through Pester.

## Mission

This template gives new PowerShell repositories a ready-to-use development baseline that can be used locally, in a Dev Container, or in GitHub Codespaces.

The goal is to reduce credential exposure, improve environmental consistency, and make it easier to work from almost anywhere without rebuilding the same setup each time.

By using Docker-based development environments, third-party module execution, cloud CLI operations, and script testing can be performed inside a Linux-based workspace instead of directly on the host operating system.

## Architecture And Stack

- **Runtime:** PowerShell 7.4.x (LTS) on Ubuntu 22.04
- **Development Modes:** Local VS Code, Docker Dev Containers, and GitHub Codespaces
- **Container Runtime:** Docker Desktop via WSL 2 backend for local container use
- **Isolation Strategy:** The container is intended to minimize exposure of host credentials and host-resident developer tooling inside the development environment
- **Credential Separation:** GitHub Copilot and similar authenticated extensions are intentionally excluded from the container environment
- **Ephemeral Cloud Identity:** Cloud authentication is expected to occur inside the container session when needed by using commands such as `az login`
- **Governance:** Integrated `PSScriptAnalyzer`, `EditorConfig`, and Markdown linting support

## Key Features

### Automated Tooling Injection

The `Dockerfile` provisions a professional PowerShell engineering toolkit:

- **Pester:** For unit and integration testing
- **PSScriptAnalyzer:** To enforce PowerShell best practices and security rules
- **Azure CLI:** Pre-installed for cloud resource management
- **PSReadLine:** Configured for a more efficient terminal experience

### Tailored Developer Experience

The environment injects a specialized PowerShell profile that enables:

- **Predictive IntelliSense:** Leveraging local command history
- **ListView Completion:** High-visibility completion menus
- **Visual Feedback:** A clear startup message confirming the container environment has loaded

## Editor Vs Container Trust Boundary

This template distinguishes between the host editor experience and the in-container development environment.

VS Code on the host may use convenience extensions such as GitHub Copilot or pull request tooling. The development container intentionally excludes those extensions and their authentication state so that code executed inside the container does not gain access to sensitive host credentials or cached tokens.

That same repository structure also supports GitHub Codespaces, providing a browser-accessible development environment when local workstation access is not the preferred option.

## What This Template Does Not Include

This template does not ship with project-specific module code, public functions, private helpers, or Pester test implementations.

Those are expected to be added in repositories created from this template. The goal is to provide a clean baseline without placeholder business logic that downstream projects must remove.

## Expected Contents Of Repositories Created From This Template

Repositories created from this template are expected to add:

- PowerShell source files under `src`
- Pester tests under `Tests`
- project-specific documentation under `docs`
- optional module manifest and build or validation automation as needed

This template provides the environment, conventions, and structure. Downstream repositories provide the implementation.

## Prerequisites And Setup

1. **Host OS:** Windows 11 with WSL 2 enabled
2. **Tools:** Docker Desktop and VS Code with the **Dev Containers** extension
3. **Launch:** Open the folder in VS Code and select **Reopen in Container** when prompted

If you are using GitHub Codespaces instead, create a new Codespace from a repository generated from this template and open the project in the browser-based editor.

## Engineering Philosophy

> *"Zero Margin for Error"*

This template carries over a high-consequence operational mindset into Infrastructure as Code and automation work.

- **Deterministic Base Runtime:** The development container is built from a pinned PowerShell 7.4 on Ubuntu 22.04 base image to reduce environmental drift
- **Controlled Tooling Baseline:** Core development tools are installed automatically in the container so that new repositories begin from a consistent baseline, even though not every tool is currently version-pinned
- **Process Integrity:** Code is not just logic. It is a service. Linting, testing, and deliberate structure are used to keep behavior predictable
- **Respect For State:** Any function that changes a system's state should support `-WhatIf` and `-Confirm` parameters
- **Clean Development Boundary:** Development tools should not unnecessarily expose host credentials or host-resident auth state to code running in the container

## Troubleshooting

- **Rebuilding:** Use `F1 > Dev Containers: Rebuild Container Without Cache` to force a clean layer refresh
- **Line Ending Errors:** Verify your local `git config core.autocrlf` is set to `input` or `false`
- **Identity Issues:** Run `az login` inside the container terminal to authenticate your cloud session for that environment
