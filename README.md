# mn-skills

Source of truth for my agent skills. Skills live here grouped by origin
(`mine/` and `vendor/<source>/`), then get flattened into the live directory
that agent tools actually scan.

A **skill** is any directory containing a `SKILL.md`.

## Scripts

### `sync.sh` — publish skills to the live dir

Rebuilds `~/.agents/skills` (and the `~/.claude/skills` symlink) from this repo.
Run it whenever you **add, remove, rename, or edit** a skill.

```bash
bash sync.sh
```

### `vendor/matt-pocock/update.sh` — refresh vendored skills

Re-pulls the latest skills from mattpocock/skills into `vendor/matt-pocock/`.

```bash
bash vendor/matt-pocock/update.sh
```

After updating, run `sync.sh` again to publish the changes:

```bash
bash sync.sh
```
