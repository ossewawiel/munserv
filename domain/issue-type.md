# Issue type

## Definition
The category of infrastructure problem an issue describes.

## Why it exists
Types drive icons, filters, reports and, later, per-type base heat and AI classification.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.issues.domain.IssueType` |
| Database | enum `issue_type` |
| TypeScript | `IssueType` union |
| Dart | `IssueType` enum |

## Values
| Wire value | Display |
|---|---|
| `pothole` | Pothole or road damage |
| `water_leak` | Water leak |
| `sewage_leak` | Sewage leak |
| `traffic_light` | Broken traffic light |
| `street_light` | Broken street light |
| `illegal_dumping` | Illegal dumping |
| `other` | Anything else |

Known drift: the database enum also has `graffiti` (unused by the backend) and mobile has an extra `roadDamage` with no wire value (#61).

## Invariants
- Types are a closed set per release. Adding one is a migration plus all three platforms plus this file.
- Priority is never set by hand; see [heat](heat.md).

## Say / do not say
- Say **type**. Do not say "category".
- The wire value is `sewage_leak`; "sewerage" appears only in old specs.

## Decided by
Domain model v0.3 §6.
