# mn-skills

Source of truth for my agent skills. Skills live here grouped by origin
(`mine/` and `vendor/<source>/`), then get flattened into the live directory
that agent tools actually scan.

A **skill** is any directory containing a `SKILL.md`.

## Scripts

### `sync.sh` — publish skills to the live dir

Copies every skill into `~/.agents/skills` (and creates the `~/.claude/skills`
symlink). It replaces only the skills it copied last time, listed in
`~/.agents/skills/.mn-skills-manifest`, and leaves everything else in that dir
alone. It checks for duplicate names before changing anything.
Run it whenever you **add, remove, rename, or edit** a skill.

```bash
bash sync.sh
```

### `vendor.sh` — vendor skills from a git repo

Clones a repo, copies its skills folder into `vendor/<name>/`, and pins the
commit in `vendor/<name>/SOURCE.md`.

```bash
# add (or re-pull) one source
bash vendor.sh https://github.com/mattpocock/skills.git matt-pocock

# skills live somewhere other than skills/
bash vendor.sh https://github.com/some/repo --dir .claude/skills

# no args: refresh every source already under vendor/, reading each SOURCE.md
bash vendor.sh
```

`[name]` defaults to the repo owner. `--dir` defaults to `skills` (use `.` for
the repo root). The whole `vendor/<name>/` tree is replaced on each run, so the
git diff afterward shows exactly what changed upstream.

After updating, run `sync.sh` again to publish the changes:

```bash
bash sync.sh
```
