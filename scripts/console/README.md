# Factory console

A portable local dashboard over a factory's checkouts, dev services, knowledge base, GitHub state
and the eyeball flow. No build step, no CDN: Python 3 stdlib + PyYAML on the server, vanilla ES
modules on the client.

Run it with `./dashboard.sh` from the repo root, or directly with
`python3 -m scripts.console [--port 3999] [--checkout DIR]`.

## Sections

Cost (Claude Code spend and tokens per day, agent, model and story, read from the OTLP metrics the telemetry collector writes; see `infrastructure/CLAUDE.md`).

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
| `telemetry_dir` | `infrastructure/telemetry/data` | Directory holding the collector's `metrics.jsonl`, read by the Cost section. |
| `changelog` | `CHANGELOG.md` | Path to the changelog. |
| `remote` | disabled | Remote eyeball (see below): `enabled`, `bind` (default `0.0.0.0`), `token_file` (default `$XDG_STATE_HOME/<name>-console/token`, i.e. `~/.local/state/<name>-console/token`), `ports` (`web`, `backend`, `console` -- exposed to the LAN and named in the firewall command), `swagger_path` (default `/swagger-ui.html`), `ensure_services` (default `[db, backend, web]`, started in that order). `--remote` / `--local` override `enabled`. |
| `showcase` | see below | Showcase stack (`checkout_dir`, `database`, `backend_port`, `web_port`, `db_host`, `db_port`, `db_user`, `db_password`). The ports must match the `demo-*` entries in `services.yaml`. |
| `links` | `{}` | Name -> URL quick links shown on Overview. |
| `sections` | all enabled | `{overview: true, knowledge: true, design: true, eyeball: true, release: true, cost: true}` -- set any to `false` to hide it. |
| `repo` | detected via `gh repo view` | `owner/name` passed to every `gh --repo`; set only if detection is wrong. |
| `local_files` | `[mise.local.toml, .tool-versions, .mise.toml, backend/src/main/resources/application-local.yml, web/.env]` | Paths (relative to the repo root) of untracked, machine-local config copied from the main repo into the checkout -- see "Local-only config" below. |

### `services.yaml` shape

One entry per service: `cwd` (relative to the checkout), `start` (shell command), `health` (a URL
or `tcp:<port>`), `url`/`notes` for display, `manual: true` to list without starting. Optional
`prepare`: `marker` (a path, relative to `cwd`, whose absence means prepare is needed),
`newer_than` (a second path that, when newer than `marker`, also means prepare is needed),
`command` (the install command), `copy` (a list of `{src, dest}` files copied from the repo root
into the checkout when `dest` is missing). See the MunServ `services.yaml` for a worked example
covering an npm/pnpm install, a Flutter `pub get`, and copying a local config file.

`start`, `url` and `notes` accept placeholders: `{bind}` (`0.0.0.0` in remote mode, else
`localhost`), `{host}` (the LAN address in remote mode, else `localhost`), `{hostname}` and
`{api_base}` (empty in remote mode, so the web client calls its own origin; the backend's localhost
URL otherwise). `health` always probes localhost. `detached: true` marks a service whose start
command exits at once (`docker compose up -d`); `start_timeout` is the seconds `ensure` waits for
it to turn healthy.

### `accounts.yaml` and `smoke.yaml`

Same shapes the eyeball dashboard used: `accounts.yaml` is free-form, keyed by the `as` field a
check names; `smoke.yaml` is a list of checks in the same shape as a handoff's `Eyeball` block.

### Local-only config

A fresh checkout is a real `git worktree`, so it has everything git tracks -- but nothing a
tester's own working copy keeps locally and gitignored: a tool-version pin
(`mise.local.toml`/`.tool-versions`/`.mise.toml`) or a local override file
(`application-local.yml`, `web/.env`). Without one of these, a step as ordinary as `flutter pub
get` can fail with `mise ERROR No version is set for shim: flutter` in a checkout that otherwise
looks identical to the tester's own. `project.yaml`'s `local_files` lists what to copy in (see the
key table above); on every checkout create/switch, and again before every Prepare/Start (including
the mobile install/run jobs below), the console copies each listed file from the repo root into the
checkout when the repo has it, the checkout doesn't yet, and git does not track it -- never
overwriting an existing copy, never touching a file git tracks. What has been copied into a given
checkout is shown under the checkout chip on the Eyeball page ("Copied mise.local.toml,
application-local.yml from the main checkout").

### Testing on a phone

The Eyeball page's Services panel has a **Phone** card for putting the latest mobile build on a
connected phone -- the emulator's `10.0.2.2` route to the host does not exist outside the emulator,
so a phone needs this machine's own LAN address instead. The card shows that address (the first
non-loopback IPv4 the console can find), the list of `adb`-visible devices (refreshed every 10s, or
on demand with Refresh), and, per device, **Install latest** (a background job: `flutter pub get`
if needed, then `flutter build apk --debug` with `--dart-define=API_HOST=<lan ip>
--dart-define=API_PORT=<mobile.api_port>`, then `adb install -r`) and **Run** (starts `flutter run
-d <device>` with the same `--dart-define`s as a tracked process, tailable and stoppable exactly
like any other service's log). No device connected shows the exact USB/wireless-debugging steps to
connect one, plus a reminder that the emulator still works with no setup at all. `mobile.py`'s
`emulator_host`/`api_port` come from `services.yaml`'s `mobile` entry, matching
`mobile/lib/shared/providers/dio_provider.dart`'s `--dart-define=API_HOST`/`API_PORT` contract.

### Remote eyeball

With `remote.enabled` the console listens on `remote.bind` and the services bind the LAN, so a
tester on another machine can open the links while everything runs on this one. Requests from
loopback need no token; every other request (static files and API) needs the access token, sent as
the `console_token` cookie, a `?token=` query (a GET with a valid one sets the cookie and redirects
to the same path without it) or an `X-Console-Token` header, else 403. The token is created on first
start in `remote.token_file` (mode 0600) and never changes, so a bookmark keeps working. The web
client calls `/api/v1` on its own origin and the Vite proxy forwards it to the backend; handoff
`localhost` URLs are shown with the machine's address on the Eyeball page, handoffs are not edited.
Security trade-offs: `specs/architecture/decisions/007-remote-eyeball.md`.

First-time setup, once:
1. `scripts/install-console-service.sh` -- installs and starts the systemd user unit (no sudo). Add
   `loginctl enable-linger $USER` to keep it running after logout.
2. Run the firewall command shown in the Eyeball page's Remote access panel (or printed by
   `eyeball-up.sh`), e.g. `sudo ufw allow from <subnet> to any port 3000,3999,8080 proto tcp`. The
   console cannot test it from this machine; open the Web link from another machine to confirm.
3. Bookmark the console link with the token (the first lines of `journalctl --user -u
   munserv-console`, or the Console line of `eyeball-up.sh`).

Per PR, after review: `scripts/eyeball-up.sh <pr>` (or `python3 -m scripts.console ensure <pr>`
with the console running). It checks out the PR head, runs Prepare when needed, and starts db,
backend and web. A service restarts only when its process exited, the checkout HEAD differs from the
one recorded in `<checkout>/.console/running-sha` when it started, or it is unhealthy; a re-run with
nothing changed restarts nothing. It prints the Web, Swagger and Console links, the accounts the
PR's checks log in as, the latest OTP and the firewall command. A service that does not turn healthy
in `start_timeout` fails the run with its last log line.

## Notes

- Requires Python 3, PyYAML, and the `gh` CLI, logged in.
- The checkout under test is a separate `git worktree`, always added detached against
  `origin/<branch>` -- it never claims a branch name, so it does not conflict with a feature
  branch already checked out elsewhere (e.g. a factory implementer's own worktree).
- Every write to the console server's own state lives under `<checkout>/.console/` (results, logs,
  the current branch marker).
- `checkout_dir` names a directory that is a *sibling of the repo*, created on first use -- it
  need not exist beforehand, and its mere existence does not count as "checked out": the Eyeball
  stepper's Check out step is only done once that directory is a real `git worktree` on the
  selected candidate's branch (`master` for the smoke checklist). If the configured directory is
  not yet a worktree but a pre-rename directory named `<name>-eyeball` already is, the server
  reuses that one instead of starting a second checkout (a one-line notice appears next to
  Checkout on the Eyeball page); this only matters across a `checkout_dir` rename and stops
  applying once the configured directory has been checked out into.
- Pressing a step button (Prepare, Start, or "Run all steps") that needs a checkout no longer
  requires Check out to have run first: `/api/prepare` and `/api/service/start-required` both
  accept a `branch` and check it out themselves if the checkout is missing or on another branch,
  failing with a 409 and the underlying git error text only if that checkout itself fails.

## Showcase stack

`showcase.py` runs a second copy of `origin/master` for demos: worktree `../<name>-demo` (detached, only follows `origin/master`), its own database, `java -jar` backend on 8090 and `vite preview` web on 4000. API: `POST /api/showcase/update|build|start|stop`; `/api/state` carries a `showcase` block (SHA, built SHA, master SHA) and `/api/remote` the demo links and firewall command. The `demo-backend`, `demo-web` and `demo-build` rows in `services.yaml` give it health dots and logs; `demo-build` holds the build log. The TUI binds `u`, `b`, `d`, `e`.
