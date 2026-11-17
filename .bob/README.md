# .bob — the implementer gate's settings

`factory.json` tells bob's gate (the `bob-core` plugin, from the `prject-bob` marketplace) which agents it
holds and which command each one must pass before it may finish. It replaces the `Stop` hooks that used to
run `.claude/hooks/verify-platform.sh` from each implementer's frontmatter. JSON has no comments, so they
live here.

- **`agents`** maps munserv's own implementers to a bob pack name. The pack name only picks the key in
  `gates`; munserv does not install the packs.
- **`gates`** holds one command per pack. Each one runs in the implementer's worktree through `/bin/sh`.
  It keeps `verify-platform.sh`'s order: an environment probe that asks for `BLOCKED: environment` when a
  tool is missing, then the platform's lint and tests (the web gate installs `node_modules` first in a
  fresh worktree).
- **`handback`** is the marker an implementer ends with to hand a story back (`BLOCKED: <reason>`, as the
  implementer cards and the `factory` skill use it). The gate lets an agent whose last message holds it
  stop without running.

The gate also keeps what `verify-platform.sh` did: it skips a gate that already passed on the same files,
and it lets an agent stop when it hits the same red twice in a row. It writes one JSON line per decision
to `$BOB_GATE_LOG`, which the tick sets to `~/.local/state/munserv-factory/bob-gate.jsonl`.

## Setup on the machine that runs the tick (once, as the tick's user)

```bash
claude plugin marketplace add ossewawiel/prject-bob   # git credentials must reach the private repo
claude plugin install bob-core@prject-bob             # user scope: loads in headless runs
```

The tick then refreshes and updates `bob-core` before each run, records the version in the ledger, and
stops if `bob-core` is missing or disabled, because the implementers have no gate of their own any more.
