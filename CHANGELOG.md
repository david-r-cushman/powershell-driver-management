# Changelog

All notable changes to this PowerShell driver management project are documented in this file.

This project uses Semantic Versioning for the project itself. The project version is separate from the synced template guidance version shown in the README badge.

## Unreleased

### Added

### Changed
- Synced the downstream guidance baseline to template 0.15.0, including repo checks, README workflow assets, runtime-policy support files, and repo-local skills.
- Realigned the root README to the standardized downstream skeleton while preserving the script's operational, ConfigMgr-focused, and deployment-specific documentation.
- Aligned the downstream Dev Container, CI workflow, and generated environment-setup guidance to the synced runtime policy baseline.
- Cleaned up preexisting analyzer findings in the script and unit tests so the newly delivered repo checks pass cleanly.
- Hardened the GitHub Actions Pester bootstrap step to recover when `PSGallery` is missing from the runner before installing pinned Pester.
## 0.1.0 - 2026-06-22

### Added

- Added root-level `AGENTS.md` from the synced template guidance.
- Added AI governance documentation and the ADR scaffold README from `pwsh-dev-template` guidance version `0.11.0`.

### Changed

- Synced AI guidance and guardrail documentation from `pwsh-dev-template` guidance version `0.11.0`.
- Refreshed `.github/copilot-instructions.md` with the current AI coding instructions.
- Updated the README template-version badge to `template-0.11.0`.
