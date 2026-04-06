# PowerShell + AI Operating Model

This note captures a practical model for using AI as an accelerator in PowerShell development without giving up engineering ownership.

The goal is not to avoid AI. The goal is to use AI to move faster while keeping human judgment responsible for correctness, safety, and maintainability.

## Core Idea

AI can generate PowerShell quickly.

My value does not disappear when that happens. My value shifts upward into:

- defining constraints
- setting standards
- reviewing for correctness
- spotting risk
- shaping architecture
- deciding what is safe to automate
- owning the final result

AI is a drafting accelerator. I remain accountable for whether the output deserves to exist.

## What To Delegate To AI

AI is well suited for first drafts and repetitive structure, including:

- advanced function scaffolding
- parameter blocks and validation attributes
- comment-based help drafts
- Pester test skeletons
- refactoring ideas for public/private function separation
- object shaping and output formatting patterns
- documentation first drafts
- converting stated standards into candidate implementations

This is where AI can save substantial time.

## What I Must Review Myself

Generated code still requires human review anywhere operational, architectural, or safety concerns matter.

That includes:

- `ShouldProcess` placement and destructive behavior
- secret handling and credential exposure
- filesystem, network, Azure, Graph, or tenant-impacting actions
- output contract stability
- idempotence and side effects
- cross-platform behavior
- test quality and what the tests actually prove
- error handling and failure modes
- alignment with repository standards
- whether the code solves the real problem instead of just satisfying the prompt

This is where AI is often plausible but still wrong, incomplete, or unsafe.

## My Highest-Value Work

The most valuable work I do is not just typing syntax. It is:

- defining what "good" means for a given repository or script
- setting governance for generated code
- choosing architecture and structure
- identifying hidden risks
- reviewing generated output critically
- refining drafts into production-quality automation
- building reusable templates and standards
- integrating code into real operational environments
- deciding when simplicity is better than more abstraction

This is still development work. It is development through direction, review, integration, and ownership.

## Recommended Working Pattern

1. Define the task, constraints, and standards clearly.
2. Let AI produce a first draft.
3. Review the draft for correctness, safety, and maintainability.
4. Use AI again to revise based on specific feedback.
5. Make the final human decision on whether the result is acceptable.

This keeps AI in the accelerator role and keeps engineering accountability with me.

## Skills Worth Deepening

The skills that remain especially valuable in AI-assisted PowerShell work are:

- PowerShell semantics and idioms
- Pester testing judgment
- safe automation design
- error handling and observability
- identity and credential boundaries
- module and script architecture
- code review skill
- writing clear constraints and expectations for AI

These are the skills that turn generated output into trustworthy automation.

## Practical Rule

Let AI generate.

Make myself responsible for whether the result is correct, safe, maintainable, and worth keeping.
