# Shared Context - API Contracts & Cross-Platform Types

## Purpose
Single source of truth for:
- API endpoint contracts
- Shared type definitions
- Validation rules
- Error codes

Changes here must be reflected in backend, mobile, and web.

## Folder Structure

```
shared/
├── CLAUDE.md
├── api-contracts/
│   ├── issues.yaml          # OpenAPI spec for issues
│   ├── members.yaml         # OpenAPI spec for members
│   ├── sectors.yaml         # OpenAPI spec for sectors
│   └── auth.yaml            # OpenAPI spec for auth
├── types/
│   ├── issue.ts             # TypeScript definitions
│   ├── member.ts
│   ├── sector.ts
│   └── common.ts
├── validation/
│   └── rules.ts             # Shared validation rules
└── errors/
    └── error-codes.ts       # Error code definitions
```

## API Contract Format (OpenAPI 3.0)

```yaml
# Example: api-contracts/issues.yaml
openapi: 3.0.0
info:
  title: Issues API
  version: 1.0.0

paths:
  /v1/issues:
    get:
      summary: List issues
      parameters:
        - name: sectorId
          in: query
          schema:
            type: string
            format: uuid
        - name: state
          in: query
          schema:
            $ref: '#/components/schemas/IssueState'
      responses:
        '200':
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Issue'

    post:
      summary: Report new issue
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateIssueRequest'
      responses:
        '201':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Issue'

components:
  schemas:
    Issue:
      type: object
      required: [id, sectorId, type, state, location, heat, reportedAt]
      properties:
        id:
          type: string
          format: uuid
        sectorId:
          type: string
          format: uuid
        type:
          $ref: '#/components/schemas/IssueType'
        state:
          $ref: '#/components/schemas/IssueState'
        location:
          $ref: '#/components/schemas/GeoPoint'
        heat:
          type: integer
          minimum: 0
        reportedAt:
          type: string
          format: date-time

    IssueState:
      type: string
      enum: [reported, confirmed, in_progress, fixed, rejected, reopened]

    IssueType:
      type: string
      enum: [pothole, water_leak, sewerage_leak, traffic_light, street_light, illegal_dumping, graffiti, other]

    GeoPoint:
      type: object
      required: [latitude, longitude]
      properties:
        latitude:
          type: number
          minimum: -90
          maximum: 90
        longitude:
          type: number
          minimum: -180
          maximum: 180
```

## Shared Type Definitions

```typescript
// types/common.ts

// Geographic
export interface GeoPoint {
  latitude: number;   // -90 to 90
  longitude: number;  // -180 to 180
}

// Pagination
export interface PaginatedRequest {
  page?: number;      // Default: 1
  pageSize?: number;  // Default: 20, max: 100
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

// API Error
export interface ApiError {
  code: string;       // Machine-readable code
  message: string;    // Human-readable message
  details?: Record<string, string[]>;  // Field-specific errors
}
```

```typescript
// types/issue.ts

export const ISSUE_STATES = [
  'reported',
  'confirmed',
  'in_progress',
  'fixed',
  'rejected',
  'reopened',
] as const;

export type IssueState = typeof ISSUE_STATES[number];

export const ISSUE_TYPES = [
  'pothole',
  'water_leak',
  'sewerage_leak',
  'traffic_light',
  'street_light',
  'illegal_dumping',
  'graffiti',
  'other',
] as const;

export type IssueType = typeof ISSUE_TYPES[number];

export interface Issue {
  id: string;
  sectorId: string;
  reporterId: string;
  type: IssueType;
  state: IssueState;
  location: GeoPoint;
  heat: number;
  description?: string;
  reportedAt: string;  // ISO 8601
  updatedAt: string;   // ISO 8601
}

export interface CreateIssueRequest {
  type: IssueType;
  location: GeoPoint;
  description?: string;
  photoIds: string[];  // Already uploaded photo IDs
}

export interface UpdateIssueStateRequest {
  state: IssueState;
  reason?: string;
}
```

## Error Codes

```typescript
// errors/error-codes.ts

export const ERROR_CODES = {
  // Authentication (1xxx)
  AUTH_INVALID_CREDENTIALS: 'E1001',
  AUTH_TOKEN_EXPIRED: 'E1002',
  AUTH_INSUFFICIENT_PERMISSIONS: 'E1003',
  AUTH_OTP_INVALID: 'E1004',
  AUTH_OTP_EXPIRED: 'E1005',

  // Validation (2xxx)
  VALIDATION_FAILED: 'E2001',
  VALIDATION_INVALID_LOCATION: 'E2002',
  VALIDATION_PHOTO_REQUIRED: 'E2003',

  // Issues (3xxx)
  ISSUE_NOT_FOUND: 'E3001',
  ISSUE_INVALID_STATE_TRANSITION: 'E3002',
  ISSUE_OUTSIDE_SECTOR: 'E3003',

  // Members (4xxx)
  MEMBER_NOT_FOUND: 'E4001',
  MEMBER_ALREADY_EXISTS: 'E4002',
  MEMBER_NOT_IN_SECTOR: 'E4003',

  // Sectors (5xxx)
  SECTOR_NOT_FOUND: 'E5001',
  SECTOR_BOUNDARY_INVALID: 'E5002',

  // Photos (6xxx)
  PHOTO_UPLOAD_FAILED: 'E6001',
  PHOTO_TOO_LARGE: 'E6002',
  PHOTO_INVALID_FORMAT: 'E6003',

  // Server (9xxx)
  SERVER_ERROR: 'E9001',
  SERVICE_UNAVAILABLE: 'E9002',
} as const;

export type ErrorCode = typeof ERROR_CODES[keyof typeof ERROR_CODES];
```

## Validation Rules

```typescript
// validation/rules.ts

export const VALIDATION = {
  // Photo
  photo: {
    maxSizeBytes: 10 * 1024 * 1024,  // 10MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
    maxPhotosPerIssue: 5,
    maxAgeHours: 24,  // Photo must be taken within last 24h
  },

  // Issue
  issue: {
    descriptionMaxLength: 500,
  },

  // Member
  member: {
    pinLength: 4,
    phonePattern: /^\+[1-9]\d{7,14}$/,  // E.164 format
  },

  // Pagination
  pagination: {
    defaultPageSize: 20,
    maxPageSize: 100,
  },
} as const;
```

## State Transitions

```typescript
// types/issue-state-machine.ts

export const ALLOWED_TRANSITIONS: Record<IssueState, IssueState[]> = {
  reported: ['confirmed', 'rejected'],
  confirmed: ['in_progress', 'rejected'],
  in_progress: ['fixed', 'rejected'],
  fixed: ['reopened'],
  rejected: [],
  reopened: ['confirmed'],
};

export function canTransition(from: IssueState, to: IssueState): boolean {
  return ALLOWED_TRANSITIONS[from].includes(to);
}
```

## Keeping Platforms in Sync

When modifying shared contracts:

1. **Update shared/ first** — This is the source of truth
2. **Update backend** — Kotlin DTOs and validation
3. **Update mobile** — Dart models and API calls
4. **Update web** — TypeScript types and API calls

### Platform-Specific Notes

| Platform | How to Use Shared Types |
|----------|------------------------|
| Backend (Kotlin) | Reference for DTO structure, copy enum values |
| Mobile (Flutter) | Reference for Freezed models, copy enum values |
| Web (React) | Can import directly if using TypeScript types |

## Contract Change Checklist

- [ ] Update OpenAPI spec in `api-contracts/`
- [ ] Update TypeScript types in `types/`
- [ ] Update error codes if new errors added
- [ ] Update validation rules if constraints change
- [ ] Notify: backend, mobile, web to sync
- [ ] Store decision in memory MCP: `decision:api:{change-topic}`
