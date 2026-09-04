---
name: branch-summary
description: Generate a concise branch summary from branch changes. Helps reviewers understand intent, impact, and risk before reading code. Use when a user asks to summarize a branch, describe branch changes, generate a PR summary, or wants a quick overview of what a branch does.
---

# Branch Summary

Generate a high-signal summary that helps reviewers understand **what changed, why, and what to watch out for** — before they read a single line of code.

## Workflow

This skill is fully non-interactive so it can run unattended (e.g. from a GitHub `@claude` comment). Do **not** prompt the user — infer everything from the branch itself.

1. Determine the **base branch**: use the branch the user named in their request; otherwise default to `main`.
2. Run `bash scripts/branch-info.sh <base-branch>`
3. From the script output, extract:
   - Commit log (narrative of what was done)
   - Churn stats (where the work concentrated)
   - New files (what was introduced)
   - Diff stats (scale of changes)
4. Read diffs to understand the actual changes — use `git diff origin/<base-branch>...HEAD` for small branches (≤10 files), or batch per-file diffs for larger ones. Skim auto-generated and low-signal files (lock files, bundled output) — don't analyze them deeply.
5. **Infer** the change type (bug fix / feature / refactor / chore) and the reason from the commit messages and diffs. If it's genuinely ambiguous, say so briefly rather than guessing — never fabricate a motivation.
6. Synthesize into the output format below. Every section must be grounded in what you read from the diffs and commits — do not speculate or pad.

## Output Format

Use [output-template.md](output-template.md) for structure.

## Principles

- **Concise over complete.** Reviewers want signal, not noise. If a section adds nothing, omit it.
- **Intent over mechanics.** "Adds auth middleware to protected routes" beats "Modified 5 files in src/routes".
- **Flag risk, don't dramatize.** Mention what could break and why — skip the alarmism.
- **Trust the diff.** Derive intent from code changes and commit messages. Don't invent motivation.
- **Group related changes.** If 8 files all serve one goal, describe the goal once — don't list each file.
