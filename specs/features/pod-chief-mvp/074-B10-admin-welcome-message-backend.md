---
issue: 95
story: B10
title: "New administrator receives a welcome message"
platform: backend
status: completed
depends_on: []
touches:
  - domain
  - backend/src/main/kotlin/com/munserv/messages
  - backend/src/main/kotlin/com/munserv/pod
  - backend/src/main/resources/db/migration
  - mobile/lib/shared/models
  - specs/contracts
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-09-06"
files_changed:
  - domain/language.yaml
  - domain/message.md
  - specs/contracts/types.md
  - specs/contracts/api.md
  - backend/src/main/resources/db/migration/V036__add_admin_welcome_message_type.sql
  - backend/src/main/kotlin/com/munserv/shared/enums/MessageType.kt
  - backend/src/main/kotlin/com/munserv/messages/service/MessageFactory.kt
  - backend/src/main/kotlin/com/munserv/pod/service/PodAdministratorService.kt
  - backend/src/main/kotlin/com/munserv/pod/api/PodAdministratorController.kt
  - backend/src/test/kotlin/com/munserv/messages/service/MessageFactoryTest.kt
  - backend/src/test/kotlin/com/munserv/pod/service/PodAdministratorServiceTest.kt
  - backend/src/test/kotlin/com/munserv/pod/api/PodAdministratorControllerTest.kt
  - mobile/lib/shared/models/message.dart
  - mobile/lib/shared/models/message.g.dart
  - mobile/lib/features/messages/presentation/pages/message_detail_page.dart
  - mobile/lib/features/messages/presentation/widgets/message_list_tile.dart
tests_added:
  - "MessageFactoryTest.AdminWelcome > should create an admin welcome message for a new administrator"
  - "MessageFactoryTest.AdminWelcome > should carry the initial tasks and role in metadata"
  - "PodAdministratorServiceTest > should create a welcome message when the administrator is created"
  - "PodAdministratorServiceTest > should not create a message when creation fails"
  - "PodAdministratorServiceTest > should return the result of the admin service unchanged"
  - "PodAdministratorControllerTest.CreateAdministrator > should send a welcome message when the administrator is created"
---

# B10 · New administrator receives a welcome message (Backend)

Read `domain/README.md`, `domain/message.md` and `domain/admin-role.md` for every term used below.
This handoff is complete on its own; do not read the feature spec or other stories' handoffs.

## Outcome
An administrator created through `POST /pod/administrators` finds an unread `admin_welcome` message
in `GET /messages` listing the tasks that start their onboarding.

## Acceptance criteria
- [x] `admin_welcome` is a message type in `domain/language.yaml`, `domain/message.md`, `com.munserv.shared.enums.MessageType`, the `message_type` database enum, `specs/contracts/types.md` and the Dart `MessageType`
- [x] `POST /pod/administrators` creates one unread `admin_welcome` message addressed to the newly created administrator (`recipientType: "admin"`, `senderType: "system"`, `actionType: "acknowledge"`)
- [x] The message body names the administrator and its `metadata.tasks` carries the initial tasks as a list of strings
- [x] `GET /messages` returns that message to the new administrator, and the unread count includes it
- [x] `python3 scripts/validate-domain-language.py` exits 0 and `./gradlew ktlintCheck test` passes

## Visual (ui stories only)
None.

## Contract
No new endpoint. `specs/contracts/types.md` § `Message` and § `MessageType` gain one value; the wire
shape of a welcome message, as W16 (#27) consumes it:
```json
{
  "type": "admin_welcome",
  "title": "Welcome to MunServ",
  "body": "Welcome, Jane Ward. Your administrator account is ready. Complete the tasks below to get started.",
  "recipientId": "<new admin id>",
  "recipientType": "admin",
  "senderId": null,
  "senderType": "system",
  "status": "unread",
  "actionType": "acknowledge",
  "metadata": { "tasks": ["...", "...", "..."], "role": "pod_admin" }
}
```
`metadata.tasks` is a JSON array of strings and nothing else; the web renders it as a list.

## Steps

The enum value `admin_welcome` must land in **six** places in the same PR, or
`scripts/validate-domain-language.py` (step 1 vs step 3) and the platform cards' "a new enum value
that is not also in the backend, mobile and `domain/`" rule fail: `domain/language.yaml`,
`domain/message.md`, the Flyway migration, `MessageType.kt`, `mobile/lib/shared/models/message.dart`
and `specs/contracts/types.md`. The validator replays enum DDL and compares the database enum with
`values.message_type`, so steps 1 and 3 must agree exactly.

1. `domain/language.yaml`: append `admin_welcome` to `concepts.message.values.message_type` (after
   `monthly_report`). `domain/message.md`: add `admin_welcome` to the "Types:" sentence and add an
   invariant bullet: `admin_welcome` is created when an administrator account is created and carries
   its initial tasks in `metadata.tasks`.
2. `specs/contracts/types.md`: add the row `| admin_welcome | Welcome message with initial tasks for
   a new administrator |` to the `MessageType` table. `specs/contracts/api.md`: under `## Messages`,
   add one sentence — `admin_welcome` messages are created by `POST /pod/administrators` and carry
   `metadata.tasks`, a list of strings.
3. `backend/src/main/resources/db/migration/V036__add_admin_welcome_message_type.sql` (new; use the
   next free V number if V036 is taken on master): `ALTER TYPE message_type ADD VALUE 'admin_welcome';`
   with the same header comment block as `V024__add_ground_admin_invitation_accepted_message_type.sql`.
4. `backend/src/main/kotlin/com/munserv/shared/enums/MessageType.kt`: add
   `ADMIN_WELCOME("admin_welcome")` as the last entry. There is no enum test package; step 5's
   factory test covers the mapping.
5. `backend/src/main/kotlin/com/munserv/messages/service/MessageFactory.kt`: in the
   `// ============ System Messages ============` block add
   `fun adminWelcome(recipientId: UUID, displayName: String, role: String): MessageEntity` returning
   `MessageEntity(type = MessageType.ADMIN_WELCOME, title = "Welcome to MunServ", body = "Welcome, $displayName. Your administrator account is ready. Complete the tasks below to get started.", recipientId = recipientId, recipientType = "admin", senderType = "system", actionType = "acknowledge", metadata = mapper.writeValueAsString(mapOf("tasks" to INITIAL_ADMIN_TASKS, "role" to role)))`.
   Add `private val INITIAL_ADMIN_TASKS = listOf("Change your temporary password.", "Complete your profile (optional, you can skip it).", "Open Messages to see what needs your attention.")`
   at the top of the object beside `mapper`. Test:
   `backend/src/test/kotlin/com/munserv/messages/service/MessageFactoryTest.kt`, new
   `@Nested inner class AdminWelcome` — `should create an admin welcome message for a new administrator`
   (type, title, body contains the display name, `recipientType` "admin", `senderType` "system",
   `actionType` "acknowledge", `status` UNREAD) and
   `should carry the initial tasks and role in metadata` (parse `message.metadata` with
   `jacksonObjectMapper().readTree(...)`; assert three non-blank task strings and the role).
6. `backend/src/main/kotlin/com/munserv/pod/service/PodAdministratorService.kt` (new): `@Service`
   taking `AdminManagementService` and `com.munserv.messages.service.MessageService`, with
   `@Transactional fun createAdministrator(command: CreateAdminCommand, createdBy: AdminId): AdminResult`
   that delegates to `adminService.createAdmin(...)` and, only when the result is
   `AdminResult.Created`, calls `messageService.createMessage(MessageFactory.adminWelcome(result.admin.id.value, result.admin.displayName, result.admin.role.toDbValue()))`
   before returning the untouched result. `MessageService.createMessage` is the messages module's
   entry point; do not touch `MessageRepository` from the pod package. Test:
   `backend/src/test/kotlin/com/munserv/pod/service/PodAdministratorServiceTest.kt` (new, MockK, no
   Spring context) — `should create a welcome message when the administrator is created`
   (capture the `MessageEntity` and assert type, recipient id and unread status),
   `should not create a message when creation fails` (stub `AdminResult.EmailAlreadyExists`, then
   `verify(exactly = 0) { messageService.createMessage(any()) }`), and
   `should return the result of the admin service unchanged`.
7. `backend/src/main/kotlin/com/munserv/pod/api/PodAdministratorController.kt`: inject
   `PodAdministratorService` alongside the existing `adminService` and call
   `podAdministratorService.createAdministrator(command, actorId)` **in `createAdministrator` only**;
   every other endpoint keeps calling `adminService`. Test:
   `backend/src/test/kotlin/com/munserv/pod/api/PodAdministratorControllerTest.kt`: add
   `@MockkBean private lateinit var podAdministratorService: PodAdministratorService` and restub the
   four cases in `inner class CreateAdministrator` from `adminService.createAdmin(any(), testAdminId)`
   to `podAdministratorService.createAdministrator(any(), testAdminId)` (same returns, same
   assertions); add `should send a welcome message when the administrator is created` only if you can
   assert it through the mocked service call, not by reaching into the repository.
8. `mobile/lib/shared/models/message.dart`: add `@JsonValue('admin_welcome') adminWelcome` as the
   last `MessageType` constant and `adminWelcome => 'Welcome'` to the `displayName` switch (it is
   exhaustive and will not compile otherwise). Then run
   `cd mobile && dart run build_runner build --delete-conflicting-outputs` so `message.g.dart` maps
   the new value. No mobile test is required; `flutter analyze` and the existing tests must stay green.

## Do not
- Do not add the welcome message to `AdminManagementService` or to `AdminManagementController`
  (`/admins`): this story is scoped to `POST /pod/administrators`, and changing
  `AdminManagementService`'s constructor churns every test that builds it.
- Do not add the other missing Dart value (`ground_admin_invitation_accepted`) or any other enum
  value: one value, six files, nothing else.
- Do not create a "welcome" table, an email, a push notification or a second message per admin.
  `domain/message.md` says the message is the record; delivery channels are a future feature.
- Do not make the message actionable beyond `acknowledge`, and do not touch `MessageService`'s
  action handling.
- Do not touch web (`web/src`): W16 (#27) consumes this and is a separate story.
- Do not renumber or edit existing migrations; `ALTER TYPE ... ADD VALUE` is the only legal change.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
python3 scripts/validate-domain-language.py
cd backend && ./gradlew ktlintCheck test
cd ../mobile && dart format lib test && flutter analyze --fatal-infos && flutter test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: New administrator gets a welcome message
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - Click "Add administrator", enter a new email and display name, pick the Pod Admin role, submit.
    - Copy the temporary password shown in the confirmation.
    - Log out, then log in as the new administrator with that temporary password and set a new one.
    - Open http://localhost:3000/messages.
  expect: One unread message of type "Welcome" addressed to the new administrator, listing the initial tasks, and the sidebar Messages badge shows 1.
- id: E2
  title: Failed creation sends nothing
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - Click "Add administrator" and submit with the email of an administrator that already exists.
  expect: The form shows the duplicate-email error and no new message appears for anyone (check the pod chief's own messages list stays unchanged).
- id: E3
  title: Mobile still renders every message type
  as: member
  services: [db, backend, mobile]
  url: Messages screen
  steps:
    - Log in as the member (OTP from the backend log) and open Messages.
  expect: The list loads without error; existing message types keep their icons and labels.
```
