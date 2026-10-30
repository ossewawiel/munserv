# Quick login: implementation plan

Plan step: S46. Read `spec.md` in this folder for the decisions and the build-input contract.

## Phases

| Phase | Stories | Who | Gate to the next phase |
|---|---|---|---|
| 1 | I1 (#205), I3 (#206) in parallel | main session | both merged; `python3 scripts/demo_accounts.py web` prints six admin entries |
| 2 | I2 (#207) | main session | merged; the console restarted on master so the new wiring runs |
| 3 | Designer canvases for W31 and M8 | `designer` | user approves both canvases |
| 4 | W31 (#208), M8 (#209) in parallel | `web-implementer`, `mobile-implementer` via `/factory run` | reviewer approves, eyeball passes, merged |
| 5 | Feature done check | user | see `spec.md` § Done check |

Phase 3 can start at any time; only phase 4 waits for it.

## Dependencies

```
I1 #205 ──> I2 #207 ──┬──> W31 #208 (needs approved canvas)
                      └──> M8  #209 (needs approved canvas)
I3 #206 (independent)
```

- I2 needs I1's script.
- W31 and M8 need I2 only so their eyeball checks get the input on the eyeball stack and on a
  phone without manual setup. Their code depends only on the contract in `spec.md`.
- I3 is independent. If W31 or M8 merges after I3, I3 also guards them.

## Touches (for serialising)

| Story | Folders |
|---|---|
| I1 | `domain/`, `scripts/console/accounts.yaml`, `scripts/`, `.gitignore`, `.github/workflows/ci.yml` |
| I3 | `scripts/`, `.github/workflows/ci.yml` |
| I2 | `scripts/console/` |
| W31 | `web/src/features/auth`, `web/src/components/molecules`, `web/src/shared/types`, `web/src/locales`, `domain/language.yaml` |
| M8 | `mobile/lib/features/auth`, `mobile/lib/l10n`, `mobile/widgetbook`, `mobile/test`, `domain/language.yaml` |

I1 and I3 both edit `ci.yml` (different jobs). Merge one, then rebase the other. W31 and M8
both append to the `demo_account` entry in `domain/language.yaml`, so the second to merge rebases.

## After the last merge
1. TUI `u`, then `b`, then `d`: update, build and start the showcase.
2. Run the feature done check in `spec.md`.
3. Mark plan step S46 done.
