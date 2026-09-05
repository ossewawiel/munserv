# Heat

## Definition
The computed urgency score of an issue, 0 to 100, driven by how many members have reported it. It replaces manual priority.

## Why it exists
Removing subjective priority keeps treatment consistent. Ten separate reports of one pothole should outrank one report of another without anyone deciding so.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `IssueService.calculateHeat`, `com.munserv.admin.domain.HeatReportItem` |
| Database | `issues.heat` |
| TypeScript | `HeatReport`, `HeatReportItem`, `HeatIndicator` component |
| Dart | `HeatColors`, heat badge on `IssueCard` |

## Formula, as implemented
```
heat = min(100, 10 + 5 × (reportCount − 1))
```
A new issue has heat 10. Each additional report adds 5. The cap is 100.

The domain model reserves two more factors for later: time open and a base heat per type. Neither is implemented; do not describe them as current behaviour.

## Invariants
- Heat is recalculated by the backend whenever `reportCount` changes; clients never compute it.
- The heat report lists open issues ordered by heat descending.

## Say / do not say
- Say **heat**. Do not say "priority", "severity" or "score" in product text.

## Decided by
Domain model v0.3 §4.4; implementation in `IssueService`.
