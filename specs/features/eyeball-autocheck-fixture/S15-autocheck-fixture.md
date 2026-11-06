---
issue: 0
story: S15
title: Fixture that exercises the auto checks of an open PR
platform: backend
status: pending
depends_on: []
touches: []
ui: false
user_facing: true
design_canvas: ""
design_artboards: []
design_approved: false
created_by: claude
created_at: "2026-11-02"
files_changed: []
tests_added: []
---

# S15 · Fixture that exercises the auto checks of an open PR (Backend)

Read `domain/README.md` for every term used below. This PR changes no code. It is held as a draft, shows the console one open PR whose handoff has auto checks, and is closed unmerged when the check is done.

## Outcome
The console lists this PR and pre-ticks E1, E3 and E4 with their evidence.

## Acceptance criteria
- [ ] Each auto check shows Pass or Fail with its responses or screenshot.

## Contract
None.

## Steps
None. This is a fixture.

## Do not
- Merge this PR.

## Done when
```bash
python3 scripts/validate-domain-language.py
```

## Eyeball
Copied from the completed #163 handoff: E1 and E3 are probes, E4 is a page check.

```yaml
- id: E1
  title: Anonymous photo delete is refused
  as: none
  auto: true
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Photos/deletePhoto
  probe:
    method: DELETE
    path: /api/v1/photos/00000000-0000-0000-0000-000000000000
    expect_status: 401
    expect_body: [UNAUTHENTICATED, Authentication required]
  steps:
    - Do not press Authorize. If a token is set, press Authorize, then Logout.
    - Open the deletePhoto operation, press Try it out, enter photoId 00000000-0000-0000-0000-000000000000 and press Execute.
  expect: The response is 401 with body {"error":{"code":"UNAUTHENTICATED","message":"Authentication required"}}. Before the fix the same call answered 404.
- id: E3
  title: Public routes still work without a token
  as: none
  auto: true
  services: [db, backend, web]
  url: http://localhost:3000/register
  probe:
    - path: /api/v1/sectors
      expect_status: 200
    - path: /actuator/health/liveness
      expect_status: 200
      expect_body: '"status":"UP"'
  steps:
    - Open the registration page in a private window, signed out.
    - Open the sector dropdown.
    - Open http://localhost:8080/actuator/health/liveness and http://localhost:8080/swagger-ui.html in the same window.
  expect: The dropdown lists sectors. The liveness page shows {"status":"UP"}. Swagger UI loads with its operations listed.
- id: E4
  title: Signed-in web portal is unaffected
  as: sector_admin
  auto: true
  services: [db, backend, web]
  url: http://localhost:3000/issues
  page:
    expect_text: [Issues]
  steps:
    - Log in as admin@ward42.example.com / admin123.
    - Open Issues, open an issue that has photos, then open Messages.
  expect: The issue's photos render. The messages list loads. No page bounces back to the login screen.
```
