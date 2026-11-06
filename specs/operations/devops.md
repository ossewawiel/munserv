# DevOps

What exists today. Nothing is deployed: there is no staging or production environment (`infrastructure/CLAUDE.md`, "Deployment").

## Git workflow

- `master` is the only long-lived branch. Branch from the latest `origin/master`.
- Pushing a branch opens a PR and arms auto-merge (`.github/workflows/auto-pr.yml`). GitHub squash-merges when `CI status` is green.
- Commit and PR titles are Conventional Commits: `<type>(<scope>): <description>`. Types and scopes are in [`CONTRIBUTING.md`](../../CONTRIBUTING.md).
- `.claude/hooks/guard-git.sh` blocks force pushes, pushes to `master` and history rewrites.

## CI

`.github/workflows/ci.yml` runs on every push and PR. Jobs are path-filtered, and the `CI status` aggregate is the check `master` requires.

| Job | Checks |
|---|---|
| `domain` | Domain language against the code, handoff and card lint, requirement rows against GitHub, hook and script tests |
| `design` | Generated theme files match the tokens |
| `backend` | `ktlintCheck`, `test` (Testcontainers), `build`; uploads test and JaCoCo coverage reports |
| `web` | `pnpm lint`, `typecheck`, `test:run`, `build`; no demo account in the bundle |
| `visual-web` | Storybook screenshot regression; `Baseline guard` holds a changed baseline until it has the `design-approved` label |
| `mobile` | `dart format`, `flutter analyze --fatal-infos`, `flutter test`, debug APK; no demo account in the APK |
| `smoke` | On `master`: starts the database and backend with the `local` profile and runs the probe checks |

Other workflows: `standards-check.yml` (advisory, source PRs), `validate-specs.yml` (weekly drift check), `generate-changelog.yml` (on version tags), `pages.yml` (design catalogues and dashboard).

## Commands

| Platform | Lint | Test | Build |
|---|---|---|---|
| Backend | `./gradlew ktlintCheck` | `./gradlew test` | `./gradlew build` |
| Web | `pnpm lint`, `pnpm typecheck` | `pnpm test:run` | `pnpm build` |
| Mobile | `dart format --set-exit-if-changed lib test`, `flutter analyze --fatal-infos` | `flutter test` | `flutter build apk --debug` |

## Quality gates

- Every CI job above is green.
- The backend publishes a JaCoCo report. No coverage threshold is enforced.
