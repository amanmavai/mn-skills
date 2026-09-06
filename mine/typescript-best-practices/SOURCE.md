# Source

Adapted from `typescript-best-practices` in [cursor/plugins](https://github.com/cursor/plugins)
(the `pstack` plugin by poteto / Lauren Tan), MIT licensed — Copyright (c) 2026 Lauren Tan.

- Commit: 93b00b89ef425a9c1bac0d0b317dfc49c930ac99
- Adapted: 2026-09-06

Changes from upstream:

- Dropped `disable-model-invocation: true` and the Cursor-only `paths:` glob so the
  skill triggers from its description like the rest of this repo's skills.
- Widened the description with the concrete rules it covers, for better triggering.
- Inlined the two cross-references to pstack's `principle-type-system-discipline` and
  `principle-boundary-discipline` skills, which are not vendored here.

Lives in `mine/` rather than `vendor/` because it is edited, not tracked upstream.
Re-check upstream by hand if you want later changes.
