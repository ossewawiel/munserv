# DevOps

## Git Workflow

**Branching:**
- `main` - Production-ready
- `develop` - Integration branch
- `feature/*` - New features
- `fix/*` - Bug fixes

**Commits:** Conventional commits
```
feat(auth): add PIN reset flow
fix(issues): correct heat calculation
docs(api): update endpoint documentation
```

## CI/CD

**On Push:**
1. Lint
2. Type check
3. Unit tests
4. Build

**On PR:**
1. All of above
2. Integration tests
3. SonarQube analysis

**On Merge to main:**
1. All of above
2. Deploy to staging
3. E2E tests
4. Deploy to production (manual approval)

## Commands

| Platform | Lint | Test | Build |
|----------|------|------|-------|
| Backend | `./gradlew ktlintCheck` | `./gradlew test` | `./gradlew build` |
| Web | `pnpm lint` | `pnpm test` | `pnpm build` |
| Mobile | `flutter analyze` | `flutter test` | `flutter build` |

## Quality Gates

- Test coverage: ≥70%
- No critical SonarQube issues
- All tests passing
- No lint errors
