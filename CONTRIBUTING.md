# Contributing to MunServ

Work reaches `master` through the factory flow below. Agents and people follow the same rules.

## Before you start

1. Read [`domain/README.md`](domain/README.md). A term that is not there does not exist yet. A story, PR or UI string that introduces a new term is not ready until its concept file and its `domain/language.yaml` entry exist. CI runs `scripts/validate-domain-language.py`.
2. Read the card for the code you touch: [`backend/CLAUDE.md`](backend/CLAUDE.md), [`web/CLAUDE.md`](web/CLAUDE.md), [`mobile/CLAUDE.md`](mobile/CLAUDE.md), [`database/CLAUDE.md`](database/CLAUDE.md) or [`infrastructure/CLAUDE.md`](infrastructure/CLAUDE.md). The root [`CLAUDE.md`](CLAUDE.md) holds the rules that apply to every platform.
3. Before you add or change UI, check the [live catalogues](https://ossewawiel.github.io/munserv/) and `design/registry/`. A new component needs a registry row and a story or use case. A UI story needs an approved design canvas.
4. Install and sign in to the GitHub CLI (`gh auth login`). Run `scripts/setup-github-labels.sh` once on a fresh repository.

## The factory flow

The root [`CLAUDE.md`](CLAUDE.md) describes the agents. The path of one change:

1. **Issue.** Report a bug or request a feature with the issue templates (`bug_report.yml`, `feature_request.yml`). A bug goes to the `investigator`. A feature goes to the `feature-planner`, which writes stories, issues, a spec and one handoff per story per platform. A person approves the stories.
2. **Canvas.** A UI story needs an approved design canvas before anyone builds it.
3. **Implementation.** An implementer takes one handoff from `specs/features/<feature>/`, works in an isolated worktree, writes tests first and cannot finish while its platform gate is red.
4. **Branch.** Every branch starts from the latest `origin/master`:
   ```bash
   git fetch origin && git switch -c <branch> origin/master
   ```
5. **PR.** Pushing a branch opens the PR and arms auto-merge (`.github/workflows/auto-pr.yml`). Do not run `gh pr merge` yourself. Watch CI with `scripts/watch-ci.sh <pr>`. Do not use `gh pr checks --watch`: it exits green while new runs are still pending.
6. **Review.** The `reviewer` gives a verdict per acceptance criterion against the handoff and the domain language. A UI story also goes through the `design-reviewer`.
7. **Eyeball.** A UI or user-facing story (`ui: true` or `user_facing: true`) waits for a person to run the Eyeball block of its handoff. `scripts/eyeball-up.sh <pr>` prints the links. The result labels the PR `eyeball:pass` or `eyeball:fail`, and each failed check files a `source:eyeball` bug.
8. **Merge.** GitHub squash-merges when `CI status` is green.
9. **After the merge.** Sync your checkout: `git fetch origin && git switch master && git pull --ff-only`, then `git branch -d <branch>`. The `syncer` updates specs and issue labels.

`.claude/hooks/guard-git.sh` blocks force pushes, pushes to `master` and history rewrites.

## Run the gate locally

CI (`.github/workflows/ci.yml`) is required on `master`. Run the same commands before you push.

| Area | Commands |
|---|---|
| Domain | `python3 scripts/validate-domain-language.py` (the `domain` job also runs the `scripts/test-*.py` suites) |
| Backend | `cd backend && ./gradlew ktlintCheck test build` (tests use Testcontainers, so Docker must run) |
| Web | `cd web && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` |
| Design tokens | `pnpm --dir design check` |
| Web visual regression | `pnpm --dir web test:visual`; a changed baseline under `web/e2e/visual/__screenshots__/` needs the `design-approved` label |
| Mobile | `cd mobile && dart format --set-exit-if-changed lib test && flutter analyze --fatal-infos && flutter test` |

CI also runs the `standards-check` workflow (advisory) on PRs that touch source files. It flags wildcard imports, `any`/`dynamic`, hardcoded URLs and debug prints. For a manual check of enums across platforms, run `scripts/validate-enum-sync.sh`.

## Commits and PRs

Use [Conventional Commits](https://www.conventionalcommits.org/). The PR title becomes the squash-merge commit, so it follows the same shape:

```
<type>(<scope>): <description>
```

| Part | Values |
|---|---|
| Type | `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore` |
| Scope | `backend`, `web`, `mobile`, `db`, `api`, `infra`, `specs`, `ci` |

Examples: `feat(web): add the members table filter`, `fix(backend): ground admin management checks the admin role (#253)`, `chore(specs): sync FIX253 after #268`.

A PR body names the issue it closes (`Fixes #123`), the plan step if there is one, and what you ran to test it. Add screenshots for UI changes.

## Releases

Pushing a version tag (`v1.2.0`) runs `.github/workflows/generate-changelog.yml`. It regenerates `CHANGELOG.md` with git-cliff, marks the stories the commits name as done in `specs/requirements/`, and opens a pull request with the result. There is no deploy step: nothing is deployed yet.

## Where to look

| Question | Read |
|---|---|
| What does this word mean? | [`domain/`](domain/README.md) |
| What does the API accept? | [`specs/contracts/api.md`](specs/contracts/api.md), [`specs/contracts/types.md`](specs/contracts/types.md) |
| Why is it built this way? | [`specs/architecture/decisions/`](specs/architecture/decisions/) |
| How is a standard enforced? | [`specs/architecture/standards-registry.md`](specs/architecture/standards-registry.md) |
| What is the status of a story? | [`specs/requirements/`](specs/requirements/) and the GitHub issue |
