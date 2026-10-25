# mn-skills

Source of truth for my agent skills, packaged as a Claude Code plugin. Skills
live here grouped by origin (`mine/` and `vendor/<source>/`) and load straight
from this repo — there is no copy step and no separate live directory.

A **skill** is any directory containing a `SKILL.md`.

## How it loads

`.claude-plugin/plugin.json` names the directories that hold skills:

```json
"skills": ["./mine/", "./vendor/chakra-ui/", "./vendor/staltz/"]
```

Each one is scanned a single level deep for `<skill>/SKILL.md`, so the grouping
on disk is the grouping the plugin publishes. Skills appear under the plugin
name: `/mn-skills:essence`, `/mn-skills:unslop`, and so on.

`.claude-plugin/marketplace.json` lists this repo as a one-plugin marketplace
named `mn`, which is what makes it installable by name.

## Install

Two ways, and they behave differently on purpose.

**From this clone** — the plugin loads *in place*, so edits to any `SKILL.md`
take effect at the next session start with nothing to publish:

```bash
claude plugin marketplace add ~/mn/repos/mn-skills && claude plugin install mn-skills@mn
```

**From GitHub** — the plugin is copied and pinned to `version` in
`plugin.json`, so changes reach the machine only when that string changes and
you run an update. Use this on machines where the repo isn't checked out, and
in cloud sessions, which never load local personal skills:

```bash
claude plugin install mn-skills --marketplace amanmavai/mn-skills
```

## Everyday commands

```bash
claude plugin validate .            # check both manifests and every SKILL.md
claude plugin details mn-skills     # list the skills and their token cost
claude plugin disable mn-skills     # take the whole set out of play
claude plugin list                  # see what loaded, and any load errors
```

Installed from this clone, adding, editing, renaming or deleting a skill needs
no command at all — the next session reads the current files. Within a running
session, `/reload-plugins` picks changes up without restarting.

## `vendor.sh` — vendor skills from a git repo

Clones a repo, copies its skills folder into `vendor/<name>/`, pins the commit
in `vendor/<name>/SOURCE.md`, and rewrites the `skills` list in
`.claude-plugin/plugin.json` so a newly vendored source actually loads.

```bash
# add (or re-pull) one source
bash vendor.sh https://github.com/staltz/microskills.git staltz

# skills live somewhere other than skills/
bash vendor.sh https://github.com/some/repo --dir .claude/skills

# no args: refresh every source already under vendor/, reading each SOURCE.md
bash vendor.sh
```

`[name]` defaults to the repo owner. `--dir` defaults to `skills` (use `.` for
the repo root). The whole `vendor/<name>/` tree is replaced on each run, so the
git diff afterward shows exactly what changed upstream.

## Why there is no sync script

An earlier `sync.sh` flattened every skill into `~/.agents/skills`, because
Claude Code scans that directory only one level deep. Copying into a directory
it did not own meant tracking which entries were its own, guarding the rest,
and deleting before copying — which could leave the live directory short of
skills and refuse to run until it was cleaned up by hand.

The plugin manifest takes a *list* of skill directories, so the grouping here
needs no flattening, and the repo is the only copy. The ownership tracking, the
manifest file, the live directory and the publish step all went with it.
