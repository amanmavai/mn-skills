# mn-skills

Source of truth for my agent skills, published as two Claude Code plugins from
one marketplace. Skills live here grouped by origin (`mine/` and
`vendor/<source>/`) and load straight from this repo — there is no copy step
and no separate live directory.

A **skill** is any directory containing a `SKILL.md`.

## The two plugins

`.claude-plugin/marketplace.json` is the whole configuration. It names the
marketplace (`mn`) and holds one entry per plugin, each listing the
directories that plugin scans:

| Plugin | Scans | Skills | Always-on |
|---|---|---|---|
| `mn-skills` | `./mine/`, `./vendor/staltz/` | 8 | ~316 tok |
| `chakra-ui` | `./vendor/chakra-ui/` | 3 | ~557 tok |

Each listed directory is scanned a single level deep for `<skill>/SKILL.md`, so
the grouping on disk is the grouping the plugins publish. Skills appear under
their plugin's name: `/mn-skills:essence`, `/chakra-ui:chakra-ui-builder`.

Both entries use `"source": "."` — the plugin *is* this repo. There is
deliberately no `plugin.json`: with one present, each entry's `skills` would be
appended to it and both plugins would load all 11 skills.

`chakra-ui` is separate because it costs more always-on context than everything
else combined, and only applies to Chakra projects — where `chakra-ui-builder`
claims triggers as broad as "build a bar chart". It stays off by default.

## Install

Point a marketplace at the clone, then install both plugins. They load *in
place*, so edits to any `SKILL.md` take effect at the next session start with
nothing to publish:

```bash
claude plugin marketplace add ~/mn/repos/mn-skills
claude plugin install mn-skills@mn
claude plugin install chakra-ui@mn
claude plugin disable chakra-ui
```

On another machine, clone the repo first and run the same commands against that
path.

## Turn Chakra on where it belongs

In a Chakra project, add this to its `.claude/settings.json` (committed, for
everyone) or `.claude/settings.local.json` (just you):

```json
{ "enabledPlugins": { "chakra-ui@mn": true } }
```

Project scope outranks the user-level `false`, so it loads there and nowhere
else.

## Everyday commands

```bash
claude plugin validate .            # check the marketplace and every SKILL.md
claude plugin details mn-skills     # list the skills and their token cost
claude plugin list                  # see what loaded, and any load errors
```

Adding, editing, renaming or deleting a skill needs no command at all — the
next session reads the current files, and `/reload-plugins` picks changes up
without restarting. The exception is `marketplace.json` itself: after changing
which *directories* an entry scans, run `claude plugin marketplace update mn`.

## `vendor.sh` — vendor skills from a git repo

Clones a repo, copies its skills folder into `vendor/<name>/`, pins the commit
in `vendor/<name>/SOURCE.md`, and updates the `skills` lists in
`marketplace.json`.

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

The `skills` lists are rewritten from what is on disk: a directory that no
longer exists is dropped, and a newly vendored source joins `DEFAULT_PLUGIN`
(`mn-skills`) so that it loads somewhere. Move its line to another entry, or
add a new entry, if it deserves a plugin of its own. The script prints where
every directory landed.

## Why there is no sync script

An earlier `sync.sh` flattened every skill into `~/.agents/skills`, because
Claude Code scans a skills dir only one level deep. Copying into a directory
it did not own meant tracking which entries were its own, guarding the rest,
and deleting before copying — which could leave the live directory short of
skills and refuse to run until it was cleaned up by hand.

A marketplace entry takes a *list* of skill directories, so the grouping here
needs no flattening, and the repo is the only copy. The ownership tracking, the
manifest file, the live directory and the publish step all went with it.
