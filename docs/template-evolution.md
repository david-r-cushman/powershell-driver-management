# Template Evolution Notes

This repository is intended to be a living baseline for new PowerShell projects rather than a permanently frozen artifact.

Its purpose is to provide a consistent starting point for development environments, project structure, tooling, and workflow conventions. As those surrounding tools and practices change, the template may also need to change.

## Why This Template Evolves

Development templates age in several dimensions:

- PowerShell and base container images change
- tooling and extensions change
- security assumptions change
- linting and testing conventions mature
- local and cloud development workflows evolve

For that reason, this template is maintained as an intentionally evolving baseline rather than a one-time setup.

## Stability Still Matters

Ongoing maintenance does not mean the template should feel unfinished or inconsistent.

The goal is to keep the template:

- clear enough to understand quickly
- stable enough to trust as a starting point
- flexible enough to support real project work
- maintained enough to remain relevant over time

Changes to the template should improve clarity, usability, safety, or maintainability. They should not create unnecessary churn.

## Design Principles For Changes

Updates to this template should generally follow these principles:

- keep README claims aligned with what the repository actually implements
- prefer deliberate tradeoffs over overstated guarantees
- optimize for practical day-to-day development use
- preserve a clean starting point for repositories created from the template
- separate durable guidance from temporary working notes
- keep security boundaries explicit

## What This Means For Downstream Repositories

Repositories created from this template should be treated as their own projects.

This template may continue to evolve after a downstream repository is created, but that does not mean every downstream repository must continuously adopt every template change. Future updates should be evaluated intentionally based on project needs.

## Maintenance Mindset

The template should be reviewed periodically with questions such as:

- does the documentation still match the implementation
- do the container and editor configurations still reflect current intent
- are the security assumptions still valid
- are the default tools and conventions still useful
- has the template become clearer or more confusing over time

The goal is not to make the template perfect. The goal is to keep it owned, coherent, and useful.
