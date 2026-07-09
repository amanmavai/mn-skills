# mn-skills

Source of truth for my agent skills. Skills are grouped by origin here, then
flattened into the live directory that agent tools actually scan.

## Layout

```
mn-skills/
├── sync.sh          # rebuilds the live dir from this repo
├── mine/            # skills I author
│   └── <skill>/SKILL.md
└── vendor/          # skills pulled from online sources, grouped by source
    └── <source>/    # e.g. matt-pocock
        └── <skill>/SKILL.md
```

A **skill** is any directory containing a `SKILL.md`. It may also hold helper
`.md` files and subfolders — `SKILL.md` just has to sit at the skill's root.

## How syncing works

- Live dir: `~/.agents/skills` — a **flat** dir, one folder per skill. This is
  what tools discover (they scan one level deep for `*/SKILL.md`).
- `~/.claude/skills` is a symlink to `~/.agents/skills`, so both locations serve
  the same skills.
- `sync.sh` **removes** the live dir and rebuilds it by copying every skill from
  `mine/` and `vendor/*/` into it, flattened. Skill directory names must be
  unique across all sources (the script aborts on a collision).

```bash
./sync.sh            # rebuild the live dir
./sync.sh --dry-run  # preview, change nothing
```

Run `sync.sh` whenever you **add, remove, or rename** a skill. Editing a skill's
contents also requires a re-sync, since the live dir holds copies.

## Adding skills

- **Your own:** create `mine/<name>/SKILL.md`, then `./sync.sh`.
- **From a source:** drop it under `vendor/<source>/<name>/`, then `./sync.sh`.
  Refreshing a source later = replace that source's folder and re-sync; git then
  shows exactly what upstream changed.
