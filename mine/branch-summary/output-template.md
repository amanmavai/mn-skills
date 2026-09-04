# Output Template

---

## Branch Summary: `<branch-name>` → `<base-branch>`

**<one-line description of what this branch does>**

**Type**: {change_type — inferred from commits/diffs; omit if unclear}
**Why**: {reason — inferred from commits/diffs; omit if unclear}

### Visual Overview

<!-- ASCII diagram: architecture, data flow, or component relationships. Omit for trivial changes.-->

### [Theme heading chosen from the actual change intent.]

- One concrete evidence-backed change per bullet.
- Keep bullets specific and reviewer relevant.

### [Another theme heading.]

### Notes

- Include only when needed
- Use for risk, validation caveats, follow-ups, migration warnings, or uncertainty.

**Visual Overview**: Include when changes touch architecture, data flow, or component relationships. Useful patterns: before and after transformations, component trees, data flow pipelines. Escape entirely for config tweaks, copy updates, or renames.

## Principles

- **Grounded, not speculative** - every claim traces to the diff. If unclear, flag it.
- **Visual first** - lead with a diagram when structure changes, skip when it doesn't.
- **Why over what** - The diff shows **what** your job is **why**.
- **2-4 thematic headings** - Group by concern, not by file.
- **Name headings well** - "API Refactoring", not "Changes".
- **Skip noise** - Formatting only, lock files, and incidental changes don't earn a bullet.
