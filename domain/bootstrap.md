# Bootstrap

## Definition
The one-time process by which the super user, authenticated from environment configuration, creates the first pod chief of a fresh pod and then loses access.

## Why it exists
A fresh deployment has no administrators. Something has to create the first one without a database credential ever being shipped in code.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.bootstrap.domain.BootstrapStatus`, `BootstrapService`, `BootstrapController`, `BootstrapConfig` |
| Database | none of its own; eligibility is derived from `admins` |
| TypeScript | `CreatePodChiefRequest`, `CreatePodChiefResponse`, `features/bootstrap` |
| Dart | none |

## How it works
1. `SUPER_USER_EMAIL` and `SUPER_USER_PASSWORD` are set and `bootstrap.super-user.enabled` is true.
2. The super user logs in through the ordinary admin login; the response carries role `super_user` and a bootstrap status.
3. The super user creates the pod chief; a welcome email with a temporary password goes out.
4. Once the pod chief has completed onboarding (see [admin-role](admin-role.md)), the pod is no longer eligible and super user login is refused.
5. Later support access is a separate, temporary grant by the pod chief (stories W28 to W30, B8).

## Invariants
- Super user credentials exist only in the environment.
- Every bootstrap action is written to the [audit](audit.md) log.
- Eligibility: no onboarded pod chief exists for the pod.

## Say / do not say
- Say **bootstrap** for this process and **setup** for the pod chief's configuration work afterwards. Do not say "install".

## Decided by
specs/features/pod-chief-bootstrap (issues #37 to #49).
