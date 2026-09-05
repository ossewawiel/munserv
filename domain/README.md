# MunServ domain language

This folder is the single source of truth for the words MunServ uses. Code, specs, issues,
handoffs and UI copy use these terms exactly. If a term is not here, it is not a MunServ term
yet: add a file before you use it.

`language.yaml` mirrors these files in machine-readable form. `scripts/validate-domain-language.py`
checks in CI that every code name it lists still exists and that enum values match across
platforms. The GitHub Pages dashboard renders the same file.

## Reading order

Read in this order the first time; each file is short.

| Concept | One line |
|---|---|
| [pod](pod.md) | One independent deployment with its own database, serving one or more communities |
| [ward](ward.md) | Optional grouping of sectors inside a pod |
| [sector](sector.md) | The operational unit: a bounded area with members, admins and issues |
| [member](member.md) | A registered, approved resident who reports issues from the mobile app |
| [admin-role](admin-role.md) | The six administrator roles, their levels, onboarding, and the super user |
| [issue](issue.md) | A reported problem at a location, with photos, a type, a state and heat |
| [issue-state](issue-state.md) | The issue lifecycle and its legal transitions |
| [issue-type](issue-type.md) | The categories of problem |
| [heat](heat.md) | The computed urgency score that replaces manual priority |
| [photo](photo.md) | Evidence attached to an issue |
| [verification](verification.md) | A ground admin confirming an issue or a fix on site |
| [ground-admin](ground-admin.md) | A trusted member who verifies for their sector |
| [message](message.md) | A system notification that may require an action |
| [bootstrap](bootstrap.md) | How a fresh pod gets its first pod chief |
| [audit](audit.md) | The security log of super user actions |

## How a concept file is laid out

Every file has the same sections, in this order, so agents can read them by heading:

1. **Definition** in one sentence.
2. **Why it exists**.
3. **Code names**: the exact identifier on each platform and in the database.
4. **States and transitions** where the concept has a lifecycle.
5. **Invariants** the code enforces.
6. **Relationships** to other concepts.
7. **Say / do not say**: synonyms to avoid and the reason.
8. **Decided by**: the ADR or spec that settled it, if any.

## Rules

- Wire values are `snake_case`. Kotlin spells them `UPPER_CASE`, Dart `camelCase`, and each
  maps 1:1 to the wire value. Never invent a fourth spelling.
- "State" is for issues. "Status" is for members, admins, messages, verifications and
  ground admins. Do not mix them.
- A story or handoff that introduces a new term is not ready until the term has a file here.
- The reviewer blocks a PR that names a concept this folder does not know.
- Known drift between platforms is tracked, not hidden: see `drift_issue` in `language.yaml`.
