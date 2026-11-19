# .bob — the implementer gate's settings

`factory.json` tells bob's gate (the `bob-core` plugin, from the `prject-bob` marketplace) which agents it
holds and which command each one must pass before it may finish. It replaces the `Stop` hooks that used to
run `.claude/hooks/verify-platform.sh` from each implementer's frontmatter. JSON has no comments, so they
live here.

- **`agents`** maps munserv's own implementers to a bob pack name. The pack name only picks the key in
  `gates`; munserv does not install the packs.
- **`gates`** holds one gate per pack, run in the implementer's worktree. Node runs it through a shell:
  `command` through `/bin/sh` on Linux and macOS, `commandWindows` through `cmd.exe` on Windows (bob-core
  0.3.0 picks the one for the platform). Both keep `verify-platform.sh`'s order: an environment probe that
  asks for `BLOCKED: environment` when a tool is missing, then the platform's lint and tests (the web gate
  installs `node_modules` first in a fresh worktree). On Windows the web probe checks `pnpm`, not `mise`.
  Change a command in both forms.
- **`handback`** is the marker an implementer ends with to hand a story back (`BLOCKED: <reason>`, as the
  implementer cards and the `factory` skill use it). The gate lets an agent whose last message holds it
  stop without running.

The gate also keeps what `verify-platform.sh` did: it skips a gate that already passed on the same files,
and it lets an agent stop when it hits the same red twice in a row. It writes one JSON line per decision
to `$BOB_GATE_LOG`, which the tick sets to `~/.local/state/munserv-factory/bob-gate.jsonl`.

**Agents cannot edit the JSON here.** bob-core reads `factory.json` from the agent's own worktree, so an
implementer that could edit it could switch its own gate off. `.claude/settings.json` denies `Edit` and
`Write` on `**/.bob/**/*.json` in every session, worktrees included. Change `factory.json` by hand, in a PR.

## Setup on every machine that runs implementers (once, as that user)

```bash
claude plugin marketplace add ossewawiel/prject-bob   # git credentials must reach the private repo
claude plugin install bob-core@prject-bob             # user scope: loads in headless runs; 0.3.0 or later
```

The tick then refreshes and updates `bob-core` before each run, records the version in the ledger, and
stops if `bob-core` is missing, disabled or older than `BOB_MIN_VERSION` (0.3.0), or if `node` is not on
PATH, because the implementers have no gate of their own any more. In a plain session, `/factory run` and
`/factory story` make the same check before they dispatch an implementer, and
`.claude/hooks/guard-dispatch.sh` enforces it on every `*implementer` dispatch, in every session and in
the tick's runs. The hook counts a user-scope install, or a project or local install whose `projectPath`
is this checkout; `claude plugin list --json` reports other projects' installs as enabled too. It fails
closed: when it cannot read the plugin list, it refuses. Each check costs one `claude plugin list --json`,
about 2 s.
