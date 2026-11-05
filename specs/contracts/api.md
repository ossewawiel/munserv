# API Contract Guide

## Contract

- Base URL: `/api/v1`.
- [`openapi.json`](openapi.json) is the source of truth for routes, parameters and bodies. The backend generates it from the controllers. Never edit it by hand.
- Swagger UI: `http://localhost:8080/swagger-ui.html`.
- Deep link to one operation: `http://localhost:8080/swagger-ui/index.html#/<Tag>/<operationId>`. Write a space in a tag as `%20`.

## Changing the contract

1. Annotate the controller and the DTO.
2. Run `cd backend && ./gradlew test --tests '*OpenApiContractTest*'`. A stale file is rewritten and the test fails.
3. Review the diff of `openapi.json` and commit it.
4. Run the command again. It must pass.

CI fails when the committed file differs from what the code generates.

On a merge conflict in `openapi.json`, take either side and regenerate.

## Naming

Every route has an explicit `@Operation(operationId = ...)`, in lowerCamelCase `<verb><Noun>` with no underscores. Use `list` for a collection and `get` for one item. The noun names the resource.

Every route has at least one tag.

## Error conventions

401 `UNAUTHENTICATED`: no, expired or invalid token; 403: authenticated but not allowed.

The error bodies differ by area until [#246](https://github.com/ossewawiel/munserv/issues/246) closes:

| Body | Where |
|---|---|
| `{ error: { code, message, details? } }` | The target form |
| `{ code, message }` | Pod Settings, Pod Administrators, Support Access |
| `{ error, message }` | Authentication |
| `{ messages: string[] }` | Support Access validation |

A revoked or expired grant token gets 401 `UNAUTHENTICATED`. A token with no grant gets 403 `not_support_grant`.

## Known gaps

The old hand-written contract documented these routes, but they were never built:

- `POST /auth/verify`
- `GET /members/{id}/issues`
- `GET /members/me/notification-settings` and `PATCH /members/me/notification-settings`; mobile calls both

## History

The old hand-written contract: `git show bd32a4b:specs/contracts/api.md`.
