# Photo

## Definition
Evidence attached to an issue: a stored image with a thumbnail, captured through the app.

## Why it exists
A report without a photo is an opinion. Photos carry the location and time of the problem and give administrators something to act on.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.photos.domain.IssuePhoto`, `PhotoId`, `PhotoValidationService` |
| Database | `issue_photos` (`url`, `thumbnail_url`, `sort_order`) |
| TypeScript | photo URLs on `Issue` |
| Dart | photo URLs on `Issue`; gallery and camera pages |

## Invariants
- One to five photos per issue.
- Uploaded through the app's camera flow; gallery uploads are not allowed for now.
- Maximum 5 MB per file; JPEG, PNG or WebP.
- Storage is local disk for now (`storage.type: local`); Cloudflare R2 is the planned production store.

## Relationships
- Belongs to an [issue](issue.md).

## Say / do not say
- Say **photo**. Do not say "image", "attachment" or "upload".

## Decided by
Domain model v0.3 §7; Tech stack selection §7 (R2).
