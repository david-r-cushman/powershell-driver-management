# AI Interaction Loop

## Purpose

This document defines a repeatable workflow for interacting with AI in a way that actively enforces the AI Behavioral Contract.

The goal is to ensure AI is used as a reliable drafting accelerator while maintaining human accountability for correctness, safety, and outcomes.

---

## Core Idea

AI is not trusted by default.

AI output is:

- generated
- evaluated
- challenged
- refined
- validated

before it is accepted.

---

## The Interaction Loop

### 1. Define

Clearly define:

- the task
- constraints
- expectations (based on the AI Behavioral Contract)

**Example:**
"Provide a PowerShell solution. Ensure it is verifiable, safe, and includes assumptions."

---

### 2. Generate

Allow AI to produce an initial draft.

AI acts as a drafting accelerator.

---

### 3. Evaluate

Review the output against the AI Behavioral Contract:

- Is anything fabricated? (Truthfulness)
- Are assumptions stated? (Transparency)
- Can this be tested? (Verifiability)
- Are risks identified? (Risk Awareness)
- Does it sound overly confident? (Integrity)

---

### 4. Challenge

If the output violates any principle, explicitly challenge it.

**Examples:**

- "This violates Verifiability—provide something testable."
- "State your assumptions explicitly."
- "This is destructive—show a safe alternative."

---

### 5. Refine

Allow AI to improve the output based on feedback.

Repeat:
Evaluate → Challenge → Refine

until the output meets the required standard.

---

### 6. Validate

Test outside of AI:

- Execute scripts in a safe environment
- Write and run Pester tests
- Simulate failure conditions
- Validate against real systems or known behavior

---

### 7. Decide

Make the final human decision:

- Is it correct?
- Is it safe?
- Is it maintainable?
- Is it worth keeping?

Only accept output that meets these criteria.

---

## Mapping to Behavioral Contract

| Step       | Enforced Principles                          |
|------------|----------------------------------------------|
| Define     | Transparency, Verifiability                  |
| Evaluate   | Truthfulness, Transparency, Integrity        |
| Challenge  | All                                          |
| Refine     | All                                          |
| Validate   | Verifiability, Risk Awareness                |
| Decide     | Human Accountability (Core Principle)        |

---

## Practical Usage

This loop should be applied to:

- PowerShell script development
- Automation workflows
- Infrastructure changes
- Documentation generation
- Any AI-assisted engineering task

---

## Guiding Rule

Do not accept AI output at face value.

Use the loop to ensure all outputs are:

- correct
- safe
- verifiable
- aligned with engineering standards
