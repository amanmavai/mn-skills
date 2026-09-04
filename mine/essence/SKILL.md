---
name: essence
description: Simplify and clean existing code without changing behavior. Delete what's dead, collapse duplication, sharpen names. Use when asked to simplify, clean up, tidy, or cut complexity from a file, module, or diff.
---

# Essence

Sophistication is not complexity. It's the hard-won simplicity left after you understand the problem well enough to throw away everything that doesn't matter.

Every line is a liability. Each one must **earn** its place.

## Guardrail

Behavior stays identical. If a cut would change what the code does, stop and ask. That's a rewrite, not a simplification.

## Workflow

1. **Scope.** Default to the working diff (`git diff` / `git diff --stat`). If the user named a file or module, use that instead. State the scope in one line before touching anything.

2. **Understand.** Read the code. Trace the data flow. Grep every call site of every export you might touch. Done when you can state each unit's job in one sentence and you know who calls it. Assumptions here become bugs later.

3. **Delete.** Cut before you improve. Nothing survives on "might need it".

4. **Collapse.** Fold what's left toward one shape.

5. **Name.** Names reveal intent, so rename what made you pause while reading.

6. **Verify each step.** After every cut, run the project's own checks (typecheck, lint, tests). Green before the next cut. Small, reversible steps, each one deployable on its own.

7. **Report.** List what you removed and why, in a few lines. Flag anything you left standing that looks wrong but sits outside the scope.

## What to cut (step 3)

- Unreachable branches, unused exports, dead params, unread variables
- Options and config nobody passes; abstraction serving one caller
- `try/catch` that rethrows, wrappers that only forward, indirection with a single implementation
- Defensive checks for states the types already rule out
- Comments restating the next line, section banners, JSDoc on self-evident helpers
- Tests asserting the framework rather than your logic

## What to collapse (step 4)

- Duplicated logic into one source of truth
- Nested conditionals into early returns; deep pyramids into flat guards
- Multi-job functions into single-job ones
- Bespoke helpers into the existing utility that already does it
- Wide types and unions into the narrow one the code actually handles

## Leave it alone when

The complexity is load-bearing: a workaround with a comment naming the constraint, a branch handling a real edge case, an abstraction with several live callers, hot-path code written awkwardly on purpose. If you can't tell, it stays, and you say so in the report.

## Done when

- Every remaining line has a reason you could defend out loud
- Nothing was added that wasn't strictly needed to remove more
- Checks pass and behavior is unchanged
- The next person changing this file has less to read, not more
