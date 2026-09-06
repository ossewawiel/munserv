# Factory console

A portable local dashboard over a factory's checkouts, dev services, knowledge base, GitHub state
and the eyeball flow. No build step, no CDN: Python 3 stdlib + PyYAML on the server, vanilla ES
modules on the client.

Run it with `./dashboard.sh` from the repo root, or directly with
`python3 -m scripts.console [--port 3999] [--checkout DIR]`.

## Sections

Overview (milestones, PR pipeline, eyeball-filed issues, quick links), Knowledge (domain language,
requirements, ADRs), Design (canvases, component registry, colour tokens), Eyeball (candidates,
guided checkout/prepare/start/test/submit, services, checklist), Release (latest tag, commits,
changelog, master CI, release checklist).

## Installing into another repository

1. Copy `dashboard.sh` and `scripts/console/` (this directory) into the new repo.
2. Write `scripts/console/project.yaml` for that repo -- see the key reference below. Every key is
   optional; a missing file or a disabled section renders an empty state, never an error.
3. Write `scripts/console/services.yaml`, `accounts.yaml` and `smoke.yaml` for that repo's own dev
   services, test accounts and baseline smoke checklist (shapes below).
4. Handoffs need an `## Eyeball` section (a fenced ```yaml block, a list of `{id, title, ...}`
   checks) for the Eyeball section to build a checklist from them.
5. `python3 scripts/test-console.py`.

### `project.yaml` keys

| Key | Default | Meaning |
|---|---|---|
| `name` | the repo directory's name | Used to name the default checkout directory and shown in the top bar. |
| `port` | `3999` | Default `--port`. |
| `accent` | `#2f6fed` | The app's one accent colour. |
| `checkout_dir` | `<name>-console` | Directory name (a sibling of the repo) for the working copy under test. |
| `handoff_glob` | `specs/features` | Path `git ls-tree` searches for handoffs. |
| `story_label_prefix` | `story:` | The PR label prefix naming the story a PR implements. |
| `domain_language` | `domain/language.yaml` | Path to the domain-language YAML mirror. |
| `requirements_dir` | `specs/requirements` | Directory of requirements markdown files. |
| `adr_dir` | `specs/architecture/decisions` | Directory of ADR markdown files. |
| `registry_dir` | `design/registry` | Directory of component-registry markdown files. |
| `canvases_dir` | `design/canvases` | Directory of `<feature>/canvas.json` design canvases. |
| `tokens` | `design/tokens/color.tokens.json` | Path to a DTCG colour tokens file. |
| `changelog` | `CHANGELOG.md` | Path to the changelog. |
| `links` | `{}` | Name -> URL quick links shown on Overview. |
| `sections` | all enabled | `{overview: true, knowledge: true, design: true, eyeball: true, release: true}` -- set any to `false` to hide it. |
| `repo` | detected via `gh repo view` | `owner/name` passed to every `gh --repo`; set only if detection is wrong. |

### `services.yaml` shape

One entry per service: `cwd` (relative to the checkout), `start` (shell command), `health` (a URL
or `tcp:<port>`), `url`/`notes` for display, `manual: true` to list without starting. Optional
`prepare`: `marker` (a path, relative to `cwd`, whose absence means prepare is needed),
`newer_than` (a second path that, when newer than `marker`, also means prepare is needed),
`command` (the install command), `copy` (a list of `{src, dest}` files copied from the repo root
into the checkout when `dest` is missing). See the MunServ `services.yaml` for a worked example
covering an npm/pnpm install, a Flutter `pub get`, and copying a local config file.

### `accounts.yaml` and `smoke.yaml`

Same shapes the eyeball dashboard used: `accounts.yaml` is free-form, keyed by the `as` field a
check names; `smoke.yaml` is a list of checks in the same shape as a handoff's `Eyeball` block.

## Notes

- Requires Python 3, PyYAML, and the `gh` CLI, logged in.
- The checkout under test is a separate `git worktree`, always added detached against
  `origin/<branch>` -- it never claims a branch name, so it does not conflict with a feature
  branch already checked out elsewhere (e.g. a factory implementer's own worktree).
- Every write to the console server's own state lives under `<checkout>/.console/` (results, logs,
  the current branch marker).
