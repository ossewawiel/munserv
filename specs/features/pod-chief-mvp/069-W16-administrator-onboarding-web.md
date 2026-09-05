---
issue: 27
story: W16
title: "Pod Administrator onboarding flow"
platform: web
status: pending
depends_on: ["B-new: admin welcome message (not yet an issue - see Contract)"]
touches:
  - web/src/shared/types
  - web/src/features/messages
  - web/src/components/guards
  - web/src/test/mocks
  - web/src/locales
ui: true
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-09-05"
files_changed: []
tests_added: []
---

# W16 · Pod Administrator onboarding flow (Web)

Read `domain/README.md`, `domain/admin-role.md` and `domain/message.md` for every term used below.
This handoff is complete on its own; do not read the feature spec or other stories' handoffs.

**Most of this story already shipped.** W26 (#41) and W27 (#42) built the whole onboarding route for
*every* admin role, not just the pod chief: `ProtectedRoute` redirects `onboardingStatus: 'pending'`
to `/onboarding/change-password` and `'password_changed'` to `/onboarding/complete-profile`, and
`CompleteProfilePage` navigates to `/` on success. The only unmet acceptance criterion is the
welcome message. Your job is that message plus regression tests that pin the redirects for a
`pod_admin`.

## Acceptance criteria
- [ ] Change temp password
- [ ] Fill required profile info
- [ ] Receive welcome message with initial tasks
- [ ] Redirected to dashboard

AC1 and AC4 are already implemented; step 5 proves them for a `pod_admin` and you change no source
for them. AC2 is **already implemented as optional and skippable**, which is what
`domain/admin-role.md` mandates ("profile completion is optional and can be skipped"). Do not make
the fields required: the wording in the issue contradicts the domain, and the reviewer follows the
domain. AC3 is the new work.

## Visual (ui stories only)
The welcome message renders inside the existing `MessageDetail` body. Match artboard: to be produced
by the designer under `design/canvases/pod-chief-mvp/`. Until then, use the plain-list layout in
step 3 and do not restyle anything else in `MessageDetail`.

## Contract
`GET /messages`, `GET /messages/{id}`, `PATCH /messages/{id}/read` are in `specs/contracts/api.md`
and are already consumed by `web/src/features/messages/api.ts`. No new endpoint.

**Blocked on a backend story that does not exist yet.** `admin_welcome` is not a `MessageType`:
`domain/language.yaml` (`message_type`), `com.munserv.shared.enums.MessageType`, the `message_type`
DB enum and the Dart mirror all stop at `monthly_report`, and nothing creates a message when
`POST /pod/administrators` succeeds. Adding the value to the web union alone is forbidden by
`web/CLAUDE.md` ("a new enum value that is not also in the backend, mobile and `domain/`").

Proposed backend story to open first — **B10, "New administrator receives a welcome message"**: add
`admin_welcome` to `domain/language.yaml`, `MessageType.kt`, the `message_type` DB enum and the Dart
`MessageType`; have `PodAdministratorService` create an `admin_welcome` message for the new admin on
create, with `recipientType: "admin"`, `senderType: "system"`, `actionType: "acknowledge"` and
`metadata.tasks` as a `string[]` of the initial tasks. **Do not start this handoff before B10 is
merged.**

The message shape you consume is `Message` in `specs/contracts/types.md` /
`web/src/shared/types/message.ts`; only `type`, `title`, `body` and `metadata.tasks` matter here.

## Steps

1. `web/src/shared/types/message.ts`: add `| 'admin_welcome'` to the `MessageType` union and
   `admin_welcome: 'messages.types.adminWelcome'` to `MESSAGE_TYPE_LABELS`. Add
   `export function getWelcomeTasks(message: Message): readonly string[]` — read
   `message.metadata?.tasks`, return `[]` unless it is an array whose every entry is a string
   (`unknown` plus a guard, never `any`). Test: `web/src/shared/types/message.test.ts` —
   `should return the tasks of an admin welcome message`,
   `should return an empty list when metadata has no task array`.
2. `web/src/features/messages/components/MessageDetail.tsx`: when `message.type === 'admin_welcome'`
   and `getWelcomeTasks(message)` is non-empty, render the tasks below the body as an MUI `List` of
   `ListItem`s under a `Typography` heading `t('messages.welcome.tasksTitle')`. Key each item by its
   text, never by index. Leave every other message type's rendering untouched. Test:
   `web/src/features/messages/components/MessageDetail.test.tsx` —
   `should list the initial tasks of an admin welcome message`,
   `should not render a task list for a message without tasks`.
3. `web/src/test/mocks/handlers.ts`: add an `admin_welcome` entry to `mockMessages`
   (`status: 'unread'`, `recipientType: 'admin'`, `senderType: 'system'`,
   `metadata: { tasks: [...] }`) in the style of the neighbouring mocks.
4. `web/src/locales/{en,af,zu}/translation.json`: add `messages.types.adminWelcome` and
   `messages.welcome.tasksTitle`. Real Afrikaans and isiZulu, not English copies.
5. `web/src/components/guards/ProtectedRoute.test.tsx` (new file if absent): with a stored admin of
   role `pod_admin`, assert
   `should send a pending pod administrator to the change password page` and
   `should send a password-changed pod administrator to the complete profile page`, and
   `should render the dashboard for an active pod administrator`. No source change in this step.

## Do not
- Do not make any `CompleteProfilePage` field required and do not remove its "Skip for now" button:
  `domain/admin-role.md` says profile completion is optional, and W27 (#42) shipped it that way.
- Do not add a separate "welcome" page, banner or dialog. The welcome arrives as a message in the
  existing inbox; that is what `domain/message.md` means by message.
- Do not add `admin_welcome` to the web union before B10 has landed the same value in
  `domain/language.yaml`, Kotlin, the DB enum and Dart. CI runs
  `scripts/validate-domain-language.py` and will fail on the drift.
- Do not touch `ChangePasswordPage`, `features/onboarding/hooks.ts` or `api.ts`: they are done.
- Do not touch backend, mobile or `specs/contracts/`.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd web && pnpm lint && pnpm typecheck && pnpm test:run
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.
