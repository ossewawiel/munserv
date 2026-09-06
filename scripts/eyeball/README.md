# Eyeball dashboard

A local dashboard for the human "eyeball" gate: it turns open `story:*` pull requests (plus a
baseline smoke checklist) into a checklist derived from each PR's handoff, checks out the branch
under test into a separate working copy, starts and stops the dev services there, and files a
GitHub issue per failed check when you submit.

Run it with `./dashboard.sh` from the repo root, or directly with
`python3 scripts/eyeball.py [--port 3999] [--checkout DIR]`.

## What lives where

`scripts/eyeball.py` itself is project-agnostic: every MunServ-specific detail comes from files in
this directory.

| File | Purpose |
|---|---|
| `services.yaml` | The services the dashboard can start/stop/health-check in the checkout under test: `cwd` (relative to the checkout), `start` (a shell command), `health` (a URL or `tcp:<port>`), `url`/`notes` for display. `manual: true` lists a service without starting it (e.g. an emulator). |
| `accounts.yaml` | Test credentials shown next to each check, keyed however you like (role, email, etc). |
| `smoke.yaml` | The baseline smoke checklist, in the same shape as a handoff's `Eyeball` block: a list of `{id, title, as, url, steps, expect}`. |
| `project.yaml` | Optional. Overrides the defaults below. |
| `dashboard.html` | The UI. No build step, no dependencies. |

`project.yaml` keys (all optional):

| Key | Default | Meaning |
|---|---|---|
| `name` | the repo directory's name | Used to name the default checkout directory. |
| `port` | `3999` | Default `--port`. |
| `handoff_glob` | `specs/features` | Path (or pathspec) `git ls-tree` searches for handoffs. |
| `story_label_prefix` | `story:` | The PR label prefix that names the story a PR implements. |
| `checkout_dir` | `<name>-eyeball` | Directory name (a sibling of the repo) for the working copy under test. |
| `repo` | detected from `git remote` via `gh repo view` | `owner/name` passed to every `gh --repo`; set this only if that detection is wrong for your remote setup. |

## Copying this to another project

1. Copy `scripts/eyeball.py`, `scripts/eyeball/` (this directory, minus MunServ's own
   `accounts.yaml`/`services.yaml`/`smoke.yaml` content) and `dashboard.sh` into the new repo.
2. Write that project's own `services.yaml`, `accounts.yaml` and `smoke.yaml`.
3. Add a `project.yaml` if any default above does not fit (a different handoff location, story
   label prefix, or port).
4. Make sure every handoff still carries an `## Eyeball` section: a fenced ```yaml block that is a
   list of `{id, title, ...}` checks, following `specs/features/_template/story-handoff.md`'s
   shape if this repo's factory conventions came along too. The handoff lookup expects files named
   `<issue>-<story>-<platform>.md` (or a legacy `<story>-<platform>.md`) somewhere under
   `handoff_glob`.
5. `python3 scripts/test-eyeball.py` — its handoff-matching tests read the real tree at `HEAD`
   under `specs/features`, so update `handoff_glob` there too if you changed it.

## Notes

- Requires Python 3, PyYAML, and the `gh` CLI, logged in.
- Nothing here touches the main checkout's own branches: the working copy under test is a
  separate `git worktree`, added (never `-B`) against `origin/<branch>`.
- `python3 scripts/eyeball.py` on its own prints exactly two lines and then serves; every error —
  a failed `git`/`gh` call included — is captured and returned in the JSON response, never printed
  to the terminal.
