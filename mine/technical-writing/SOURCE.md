# Source

Adapted from `technical-writing` in [cursor/plugins](https://github.com/cursor/plugins)
(the `pstack` plugin by poteto / Lauren Tan), MIT licensed — Copyright (c) 2026 Lauren Tan.

- Commit: 93b00b89ef425a9c1bac0d0b317dfc49c930ac99
- Adapted: 2026-09-06

Changes from upstream:

- Dropped `disable-model-invocation: true` so the skill triggers from its description
  like the rest of this repo's skills.
- Dropped the `/technical-writing` slash mention from the description and widened the
  trigger list; the slash form still works.
- Pointed the two `unslop` cross-references at this repo's `mine/unslop`, naming its
  abstract-metaphor-nouns rule.

Upstream cites its own sources inline: diataxis.fr, developers.google.com/style,
asd-ste100.org (Issue 9, 2025), and Kohl, *The Global English Style Guide* (SAS Press).

Lives in `mine/` rather than `vendor/` because it is edited, not tracked upstream.
