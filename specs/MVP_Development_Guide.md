# MVP Development Guide

**Project:** MunServ | **Version:** 1.0 | **Status:** Active

*Primary reference for MVP development. Start here.*

---

## 1. MVP Philosophy

**Build working software fast, iterate based on learning.**

```
Define MVP Scope → API Contract → Mock API → Build UI → Learn → Repeat
```

### What MVP Means for MunServ

| Include | Exclude (Phase 2+) |
|---------|-------------------|
| Single sector operation | Sector groups / hierarchy |
| Basic issue reporting | AI photo analysis |
| Simple state transitions | Complex workflows |
| Phone + OTP auth | Social login, 2FA |
| Map view of issues | Offline mode |
| Basic admin functions | Advanced reporting |
| English only | Multi-language |

### Success Criteria

MVP is complete when:
- [ ] Member can register, report an issue with photo, and see it on a map
- [ ] Admin can view issues, change states, and see a basic heat list
- [ ] Both apps work against the same mock API
- [ ] Ready to swap mock for real backend

---

## 2. MVP Scope

### 2.1 Mobile App (Member)

| # | User Story | Acceptance Criteria |
|---|------------|---------------------|
| M1 | Register with phone number | Enter phone → receive OTP → verify → profile (name, address via GPS) → create PIN |
| M2 | Login with PIN/biometric | Enter PIN or use fingerprint → access app |
| M3 | View issues on map | See map centered on my sector with issue markers |
| M4 | View issue list | See list of issues, filter by type/state |
| M5 | Report new issue | Take photo → select type → confirm location → submit |
| M6 | View issue details | See photo(s), type, state, location, timestamps |
| M7 | View my reports | See list of issues I reported with current status |

### 2.2 Web Admin (Sector Administrator)

| # | User Story | Acceptance Criteria |
|---|------------|---------------------|
| W1 | Login with email/password | Enter credentials → access dashboard |
| W2 | View dashboard | See summary stats: open issues, by type, by state |
| W3 | View issues list | See paginated list, filter by type/state, sort by heat |
| W4 | View issue details | See all info, photo(s), reporter (admin only), history |
| W5 | Change issue state | Select new state → add optional note → save |
| W6 | View heat report | See issues ranked by heat score |
| W7 | View members list | See sector members (Phase 2: manage them) |

### 2.3 Explicitly Deferred

| Feature | Why Deferred | Phase |
|---------|--------------|-------|
| Member approval workflow | Collect data now, approval later | 2 |
| Member management (add/remove/warn) | Not core to proving concept | 2 |
| Sector boundary editing | Complex, use fixed test boundary | 2 |
| Push notifications | Requires backend infrastructure | 2 |
| Duplicate issue linking | Needs AI or complex UX | 2 |
| Reports export (PDF/Excel) | Nice-to-have | 2 |
| Pod/sector hierarchy | Single sector is enough for MVP | 2 |
| Community Admin role | Sector Admin sufficient for MVP | 2 |

---

## 3. Data Shapes

These are the TypeScript interfaces / Dart classes for MVP. Both platforms should use identical shapes.

### 3.1 Core Types

```typescript
// === ENUMS ===

type IssueType = 
  | 'pothole'
  | 'water_leak'
  | 'sewage_leak'
  | 'traffic_light'
  | 'street_light'
  | 'illegal_dumping'
  | 'other';

type IssueState = 
  | 'reported'
  | 'confirmed'
  | 'in_progress'
  | 'fixed'
  | 'rejected';

// === GEOMETRY ===

interface GeoPoint {
  latitude: number;   // -90 to 90
  longitude: number;  // -180 to 180
}

// === MEMBER ===

type MemberStatus = 'active' | 'pending' | 'suspended';

interface Member {
  id: string;                    // UUID
  firstName: string;             // "John"
  surname: string;               // "Doe"
  phoneNumber: string;           // E.164 format: +27821234567
  address: string;               // Reverse geocoded from GPS at registration
  registrationLocation: GeoPoint; // GPS coordinates at time of registration
  sectorId: string;              // UUID - auto-assigned from location
  status: MemberStatus;          // MVP: always 'active'. Phase 2: pending until approved
  createdAt: string;             // ISO 8601
}

// === SECTOR ===

interface Sector {
  id: string;                    // UUID
  name: string;                  // "Ward 42 - Northcliff"
  // MVP: center point only, boundary in Phase 2
  center: GeoPoint;
  // Future: boundary: GeoPolygon
}

// === ISSUE ===

interface Issue {
  id: string;                    // UUID
  type: IssueType;
  state: IssueState;
  location: GeoPoint;
  address: string | null;        // Reverse geocoded, optional
  description: string | null;    // Optional notes from reporter
  heat: number;                  // Calculated: 0-100
  photoUrls: string[];           // 1-5 photos
  sectorId: string;
  reporterId: string;            // UUID (hidden from other members)
  reportCount: number;           // How many people reported this
  createdAt: string;             // ISO 8601
  updatedAt: string;             // ISO 8601
}

// === ISSUE SUMMARY (for lists) ===

interface IssueSummary {
  id: string;
  type: IssueType;
  state: IssueState;
  location: GeoPoint;
  heat: number;
  thumbnailUrl: string;          // First photo, thumbnail size
  createdAt: string;
}

// === AUTH ===

interface AuthTokens {
  accessToken: string;           // JWT, short-lived (15 min)
  refreshToken: string;          // Longer-lived (90 days)
  expiresAt: string;             // ISO 8601
}

interface MemberProfile {
  member: Member;
  sector: Sector;
}
```

### 3.2 Dart Equivalents

```dart
// lib/shared/models/issue.dart

enum IssueType {
  pothole,
  waterLeak,
  sewageLeak,
  trafficLight,
  streetLight,
  illegalDumping,
  other;
  
  String get displayName => switch (this) {
    pothole => 'Pothole',
    waterLeak => 'Water Leak',
    sewageLeak => 'Sewage Leak',
    trafficLight => 'Traffic Light',
    streetLight => 'Street Light',
    illegalDumping => 'Illegal Dumping',
    other => 'Other',
  };
}

enum IssueState {
  reported,
  confirmed,
  inProgress,
  fixed,
  rejected;
  
  String get displayName => switch (this) {
    reported => 'Reported',
    confirmed => 'Confirmed',
    inProgress => 'In Progress',
    fixed => 'Fixed',
    rejected => 'Rejected',
  };
}

@freezed
class GeoPoint with _$GeoPoint {
  const factory GeoPoint({
    required double latitude,
    required double longitude,
  }) = _GeoPoint;
  
  factory GeoPoint.fromJson(Map<String, dynamic> json) => 
    _$GeoPointFromJson(json);
}

@freezed
class Issue with _$Issue {
  const factory Issue({
    required String id,
    required IssueType type,
    required IssueState state,
    required GeoPoint location,
    String? address,
    String? description,
    required int heat,
    required List<String> photoUrls,
    required String sectorId,
    required String reporterId,
    required int reportCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Issue;
  
  factory Issue.fromJson(Map<String, dynamic> json) => 
    _$IssueFromJson(json);
}
```

---

## 4. API Contract (MVP)

Base URL: `http://localhost:3001/api/v1` (mock server)

### 4.1 Authentication

#### Register (Request OTP)

```
POST /auth/register
```

**Request:**
```json
{
  "phoneNumber": "+27821234567"
}
```

**Response (200):**
```json
{
  "message": "OTP sent",
  "expiresInSeconds": 300
}
```

#### Verify OTP

```
POST /auth/verify-otp
```

**Request:**
```json
{
  "phoneNumber": "+27821234567",
  "otp": "123456"
}
```

**Response (200):** (New user - needs to set PIN)
```json
{
  "status": "new_user",
  "tempToken": "temp_abc123..."
}
```

**Response (200):** (Existing user)
```json
{
  "status": "existing_user",
  "tokens": {
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG...",
    "expiresAt": "2025-01-15T10:30:00Z"
  },
  "profile": {
    "member": { ... },
    "sector": { ... }
  }
}
```

#### Complete Registration (Set PIN + Profile)

```
POST /auth/complete-registration
```

**Headers:** `Authorization: Bearer {tempToken}`

**Request:**
```json
{
  "firstName": "John",
  "surname": "Doe",
  "pin": "1234",
  "location": { "latitude": -26.1350, "longitude": 27.9800 },
  "address": "42 Doreen Road, Northcliff"
}
```

**Notes:**
- `location`: GPS coordinates at time of registration (for sector auto-assignment)
- `address`: Reverse-geocoded address string from GPS, user can edit
- `sectorId` is NOT sent - server determines sector from location

**Response (201):**
```json
{
  "tokens": {
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG...",
    "expiresAt": "2025-01-15T10:30:00Z"
  },
  "profile": {
    "member": {
      "id": "member-uuid",
      "firstName": "John",
      "surname": "Doe",
      "phoneNumber": "+27821234567",
      "address": "42 Doreen Road, Northcliff",
      "registrationLocation": { "latitude": -26.1350, "longitude": 27.9800 },
      "sectorId": "sector-uuid",
      "status": "active",
      "createdAt": "2025-01-15T10:00:00Z"
    },
    "sector": {
      "id": "sector-uuid",
      "name": "Ward 42 - Northcliff",
      "center": { "latitude": -26.1367, "longitude": 27.9833 }
    }
  }
}
```

#### Login (PIN)

```
POST /auth/login
```

**Request:**
```json
{
  "phoneNumber": "+27821234567",
  "pin": "1234"
}
```

**Response (200):**
```json
{
  "tokens": { ... },
  "profile": { ... }
}
```

#### Refresh Token

```
POST /auth/refresh
```

**Request:**
```json
{
  "refreshToken": "eyJhbG..."
}
```

**Response (200):**
```json
{
  "tokens": { ... }
}
```

---

### 4.2 Issues

All issue endpoints require: `Authorization: Bearer {accessToken}`

#### List Issues

```
GET /issues?sectorId={sectorId}&state={state}&type={type}&page={page}&limit={limit}
```

**Query Parameters:**
| Param | Required | Default | Description |
|-------|----------|---------|-------------|
| sectorId | Yes | - | Filter by sector |
| state | No | all | Filter by state |
| type | No | all | Filter by type |
| page | No | 1 | Page number |
| limit | No | 20 | Items per page |
| sortBy | No | heat | `heat`, `createdAt` |

**Response (200):**
```json
{
  "items": [
    {
      "id": "issue-uuid-1",
      "type": "pothole",
      "state": "reported",
      "location": { "latitude": -26.1234, "longitude": 28.0123 },
      "heat": 75,
      "thumbnailUrl": "https://r2.example.com/thumb/photo1.jpg",
      "createdAt": "2025-01-14T08:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalItems": 45,
    "totalPages": 3
  }
}
```

#### Get Issue Details

```
GET /issues/{issueId}
```

**Response (200):**
```json
{
  "id": "issue-uuid-1",
  "type": "pothole",
  "state": "confirmed",
  "location": { "latitude": -26.1234, "longitude": 28.0123 },
  "address": "123 Main Road, Northcliff",
  "description": "Large pothole near the traffic light",
  "heat": 75,
  "photoUrls": [
    "https://r2.example.com/photos/photo1.jpg",
    "https://r2.example.com/photos/photo2.jpg"
  ],
  "sectorId": "sector-uuid",
  "reporterId": "member-uuid",
  "reportCount": 3,
  "createdAt": "2025-01-14T08:30:00Z",
  "updatedAt": "2025-01-14T10:15:00Z",
  "stateHistory": [
    {
      "state": "reported",
      "changedAt": "2025-01-14T08:30:00Z",
      "changedBy": null
    },
    {
      "state": "confirmed",
      "changedAt": "2025-01-14T10:15:00Z",
      "changedBy": "admin-uuid",
      "note": "Verified on site"
    }
  ]
}
```

#### Create Issue (Report)

```
POST /issues
Content-Type: multipart/form-data
```

**Form Fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| type | string | Yes | Issue type enum |
| latitude | number | Yes | GPS latitude |
| longitude | number | Yes | GPS longitude |
| description | string | No | Optional notes |
| photos | File[] | Yes | 1-5 photos |

**Response (201):**
```json
{
  "id": "new-issue-uuid",
  "type": "pothole",
  "state": "reported",
  "location": { "latitude": -26.1234, "longitude": 28.0123 },
  "heat": 10,
  "photoUrls": ["https://r2.example.com/photos/newphoto.jpg"],
  "createdAt": "2025-01-15T09:00:00Z"
}
```

#### Update Issue State (Admin)

```
PATCH /issues/{issueId}/state
```

**Request:**
```json
{
  "state": "confirmed",
  "note": "Verified on site visit"
}
```

**Response (200):**
```json
{
  "id": "issue-uuid",
  "state": "confirmed",
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

#### Get My Issues

```
GET /issues/mine?page={page}&limit={limit}
```

**Response (200):** Same format as List Issues

---

### 4.3 Sectors

#### List Sectors (for registration dropdown)

```
GET /sectors
```

**Response (200):**
```json
{
  "items": [
    {
      "id": "sector-uuid-1",
      "name": "Ward 42 - Northcliff",
      "center": { "latitude": -26.1234, "longitude": 28.0123 }
    },
    {
      "id": "sector-uuid-2", 
      "name": "Ward 43 - Fairlands",
      "center": { "latitude": -26.1300, "longitude": 28.0200 }
    }
  ]
}
```

---

### 4.4 Admin Endpoints

These require admin role in JWT.

#### Dashboard Stats

```
GET /admin/dashboard
```

**Response (200):**
```json
{
  "sectorId": "sector-uuid",
  "sectorName": "Ward 42 - Northcliff",
  "stats": {
    "totalOpen": 45,
    "byState": {
      "reported": 20,
      "confirmed": 15,
      "in_progress": 10,
      "fixed": 50,
      "rejected": 5
    },
    "byType": {
      "pothole": 25,
      "water_leak": 10,
      "street_light": 8,
      "other": 2
    },
    "avgResolutionDays": 4.5,
    "reportedThisWeek": 12
  }
}
```

#### Heat Report

```
GET /admin/reports/heat?limit={limit}
```

**Response (200):**
```json
{
  "generatedAt": "2025-01-15T10:00:00Z",
  "items": [
    {
      "id": "issue-uuid-1",
      "type": "sewage_leak",
      "state": "reported",
      "heat": 95,
      "daysOpen": 7,
      "reportCount": 12,
      "location": { "latitude": -26.1234, "longitude": 28.0123 },
      "thumbnailUrl": "https://..."
    }
  ]
}
```

#### Members List

```
GET /admin/members?page={page}&limit={limit}
```

**Response (200):**
```json
{
  "items": [
    {
      "id": "member-uuid",
      "displayName": "John D.",
      "phoneNumber": "+27821234567",
      "issueCount": 5,
      "joinedAt": "2025-01-10T08:00:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### 4.5 Error Responses

All errors follow this format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid phone number format",
    "details": {
      "field": "phoneNumber",
      "reason": "Must be E.164 format"
    }
  }
}
```

**Error Codes:**

| HTTP | Code | Description |
|------|------|-------------|
| 400 | VALIDATION_ERROR | Invalid request data |
| 401 | UNAUTHORIZED | Missing or invalid token |
| 403 | FORBIDDEN | Not allowed for this resource |
| 404 | NOT_FOUND | Resource doesn't exist |
| 409 | CONFLICT | Already exists (e.g., phone registered) |
| 422 | INVALID_STATE_TRANSITION | Can't change state that way |
| 500 | INTERNAL_ERROR | Server error |

---

## 5. Mock Data

### 5.1 Test Sector

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "name": "Ward 42 - Northcliff",
  "center": { "latitude": -26.1367, "longitude": 27.9833 }
}
```

### 5.2 Test Members

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440010",
    "firstName": "John",
    "surname": "Doe",
    "phoneNumber": "+27821234567",
    "address": "42 Doreen Road, Northcliff",
    "registrationLocation": { "latitude": -26.1350, "longitude": 27.9800 },
    "sectorId": "550e8400-e29b-41d4-a716-446655440001",
    "status": "active",
    "createdAt": "2025-01-10T08:00:00Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440011",
    "firstName": "Sarah",
    "surname": "Miller",
    "phoneNumber": "+27829876543",
    "address": "15 Doris Road, Northcliff",
    "registrationLocation": { "latitude": -26.1320, "longitude": 27.9870 },
    "sectorId": "550e8400-e29b-41d4-a716-446655440001",
    "status": "active",
    "createdAt": "2025-01-11T09:30:00Z"
  }
]
```

### 5.3 Test Issues

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440100",
    "type": "pothole",
    "state": "reported",
    "location": { "latitude": -26.1350, "longitude": 27.9800 },
    "address": "Cnr Doreen & Doris Road, Northcliff",
    "description": "Large pothole, about 30cm deep",
    "heat": 75,
    "photoUrls": ["https://picsum.photos/seed/pothole1/800/600"],
    "sectorId": "550e8400-e29b-41d4-a716-446655440001",
    "reporterId": "550e8400-e29b-41d4-a716-446655440010",
    "reportCount": 3,
    "createdAt": "2025-01-12T08:30:00Z",
    "updatedAt": "2025-01-12T08:30:00Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440101",
    "type": "street_light",
    "state": "confirmed",
    "location": { "latitude": -26.1380, "longitude": 27.9850 },
    "address": "42 Doreen Road, Northcliff",
    "description": "Light has been out for 2 weeks",
    "heat": 45,
    "photoUrls": ["https://picsum.photos/seed/light1/800/600"],
    "sectorId": "550e8400-e29b-41d4-a716-446655440001",
    "reporterId": "550e8400-e29b-41d4-a716-446655440011",
    "reportCount": 1,
    "createdAt": "2025-01-10T18:00:00Z",
    "updatedAt": "2025-01-11T09:00:00Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440102",
    "type": "water_leak",
    "state": "in_progress",
    "location": { "latitude": -26.1320, "longitude": 27.9870 },
    "address": "15 Doris Road, Northcliff",
    "description": "Water gushing from pavement",
    "heat": 90,
    "photoUrls": [
      "https://picsum.photos/seed/water1/800/600",
      "https://picsum.photos/seed/water2/800/600"
    ],
    "sectorId": "550e8400-e29b-41d4-a716-446655440001",
    "reporterId": "550e8400-e29b-41d4-a716-446655440010",
    "reportCount": 8,
    "createdAt": "2025-01-08T14:00:00Z",
    "updatedAt": "2025-01-13T10:30:00Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440103",
    "type": "sewage_leak",
    "state": "reported",
    "location": { "latitude": -26.1400, "longitude": 27.9820 },
    "address": "Cnr Doris & Main Road, Northcliff",
    "description": "Sewage overflow, very bad smell",
    "heat": 95,
    "photoUrls": ["https://picsum.photos/seed/sewage1/800/600"],
    "sectorId": "550e8400-e29b-41d4-a716-446655440001",
    "reporterId": "550e8400-e29b-41d4-a716-446655440011",
    "reportCount": 15,
    "createdAt": "2025-01-07T06:00:00Z",
    "updatedAt": "2025-01-07T06:00:00Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440104",
    "type": "pothole",
    "state": "fixed",
    "location": { "latitude": -26.1360, "longitude": 27.9890 },
    "address": "88 Main Road, Northcliff",
    "description": null,
    "heat": 0,
    "photoUrls": ["https://picsum.photos/seed/pothole2/800/600"],
    "sectorId": "550e8400-e29b-41d4-a716-446655440001",
    "reporterId": "550e8400-e29b-41d4-a716-446655440010",
    "reportCount": 2,
    "createdAt": "2025-01-05T10:00:00Z",
    "updatedAt": "2025-01-12T16:00:00Z"
  }
]
```

### 5.4 Test Admin User

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440020",
  "email": "admin@ward42.example.com",
  "displayName": "Ward 42 Admin",
  "sectorId": "550e8400-e29b-41d4-a716-446655440001",
  "role": "SECTOR_ADMIN"
}
```

**Test Credentials:**
- Phone (member): `+27821234567`, OTP: `123456`, PIN: `1234`
- Email (admin): `admin@ward42.example.com`, Password: `admin123`

---

## 6. Mock Server Setup

### 6.1 Option A: JSON Server (Simplest)

```bash
# In project root
cd infrastructure/mock-api

# Install
npm init -y
npm install json-server

# Create db.json with mock data (see Section 5)

# Run
npx json-server --watch db.json --port 3001
```

**Limitation:** No custom logic, basic REST only.

### 6.2 Option B: MSW (Mock Service Worker) - Recommended for Web

```bash
cd web
npm install msw --save-dev
npx msw init public/ --save
```

```typescript
// src/mocks/handlers.ts
import { http, HttpResponse } from 'msw';
import { mockIssues, mockSectors } from './data';

export const handlers = [
  http.get('/api/v1/issues', ({ request }) => {
    const url = new URL(request.url);
    const state = url.searchParams.get('state');
    
    let issues = mockIssues;
    if (state) {
      issues = issues.filter(i => i.state === state);
    }
    
    return HttpResponse.json({
      items: issues,
      pagination: { page: 1, limit: 20, totalItems: issues.length, totalPages: 1 }
    });
  }),
  
  http.post('/api/v1/auth/login', async ({ request }) => {
    const body = await request.json();
    if (body.pin === '1234') {
      return HttpResponse.json({
        tokens: { accessToken: 'mock-token', refreshToken: 'mock-refresh', expiresAt: '...' },
        profile: { ... }
      });
    }
    return HttpResponse.json({ error: { code: 'UNAUTHORIZED' } }, { status: 401 });
  }),
];
```

### 6.3 Option C: Express Mock Server (Most Flexible)

```bash
cd infrastructure/mock-api
npm init -y
npm install express cors multer
```

```javascript
// server.js
const express = require('express');
const cors = require('cors');
const multer = require('multer');

const app = express();
app.use(cors());
app.use(express.json());

const upload = multer({ dest: 'uploads/' });

// Mock data
const issues = require('./data/issues.json');
const members = require('./data/members.json');

// Endpoints
app.get('/api/v1/issues', (req, res) => {
  const { sectorId, state, type } = req.query;
  let filtered = issues;
  
  if (state) filtered = filtered.filter(i => i.state === state);
  if (type) filtered = filtered.filter(i => i.type === type);
  
  res.json({
    items: filtered,
    pagination: { page: 1, limit: 20, totalItems: filtered.length, totalPages: 1 }
  });
});

app.post('/api/v1/issues', upload.array('photos', 5), (req, res) => {
  const newIssue = {
    id: `issue-${Date.now()}`,
    type: req.body.type,
    state: 'reported',
    location: { latitude: parseFloat(req.body.latitude), longitude: parseFloat(req.body.longitude) },
    heat: 10,
    photoUrls: req.files.map(f => `http://localhost:3001/uploads/${f.filename}`),
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  issues.push(newIssue);
  res.status(201).json(newIssue);
});

// ... more endpoints

app.listen(3001, () => console.log('Mock API running on http://localhost:3001'));
```

**Recommendation:** Start with JSON Server for viewing data, move to Express when you need custom logic (auth, file uploads).

---

## 7. Development Workflow

### 7.1 Getting Started

```bash
# 1. Start mock API
cd infrastructure/mock-api
npm start

# 2. Start web dev server (new terminal)
cd web
pnpm dev

# 3. Start mobile (new terminal)
cd mobile
flutter run
```

### 7.2 Building a Feature

```
1. Check MVP scope (Section 2) - is it in scope?
2. Check API contract (Section 4) - what endpoint to call?
3. Check data shapes (Section 3) - what's the response format?
4. Build UI against mock
5. Test happy path + error states
6. PR when working
```

### 7.3 When You Need New Data/Endpoints

1. Add to mock data (Section 5)
2. Add endpoint to mock server
3. Document in this file under "API Contract"
4. Continue building

---

## 8. Screen Inventory

### 8.1 Mobile Screens

| Screen | Route | Components |
|--------|-------|------------|
| Splash | `/` | Logo, loading |
| Onboarding | `/onboarding` | 3 slides, get started button |
| Phone Entry | `/auth/phone` | Phone input, submit |
| OTP Verify | `/auth/otp` | 6-digit input, resend |
| PIN Setup | `/auth/pin-setup` | PIN input, confirm |
| PIN Login | `/auth/login` | PIN input, biometric button |
| Home / Map | `/home` | Map, issue markers, FAB |
| Issue List | `/issues` | Filter tabs, issue cards |
| Issue Detail | `/issues/:id` | Photos, info, status |
| Report Issue | `/report` | Camera, type picker, submit |
| My Issues | `/my-issues` | List of my reports |
| Profile | `/profile` | User info, settings |

### 8.2 Web Admin Screens

| Screen | Route | Components |
|--------|-------|------------|
| Login | `/login` | Email/password form |
| Dashboard | `/` | Stats cards, charts |
| Issues List | `/issues` | Table, filters, pagination |
| Issue Detail | `/issues/:id` | Full details, state change |
| Heat Report | `/reports/heat` | Ranked list, map |
| Members | `/members` | Table (view only for MVP) |

---

## 9. Expansion Notes

These are **comments for future reference**, not current requirements.

### Authentication
```
// Future: Add biometric authentication
// Future: Add refresh token rotation
// Future: Add device registration for push notifications
// Future: Add social login (Google, Apple)
```

### Issues
```
// Future: Add duplicate detection (link multiple reports)
// Future: Add AI photo classification
// Future: Add photo quality validation
// Future: Add offline queue for poor connectivity
// Future: Add issue comments/updates from admins
```

### Sectors
```
// Future: Add sector boundaries (PostGIS polygons)
// Future: Add sector hierarchy (sector groups)
// Future: Add cross-sector issue visibility
```

### Admin
```
// Future: Add member management (warn, suspend, remove)
// Future: Add PDF/Excel report export
// Future: Add scheduled reports via email
// Future: Add audit log viewer
```

### Notifications
```
// Future: Add push notifications (Firebase)
// Future: Add SMS notifications for critical issues
// Future: Add notification preferences
```

---

## 10. Checklist

### Before Starting Mobile Dev

- [ ] Mock server running
- [ ] Flutter project initialized with folder structure
- [ ] Riverpod configured
- [ ] Dio HTTP client configured with base URL
- [ ] Freezed models generated from data shapes
- [ ] Basic navigation set up

### Before Starting Web Dev

- [ ] Mock server running (or MSW configured)
- [ ] React project initialized with Vite
- [ ] React Query configured
- [ ] React Router configured
- [ ] shadcn/ui components installed
- [ ] TypeScript types created from data shapes

### MVP Complete Checklist

- [ ] All M1-M7 user stories working (mobile)
- [ ] All W1-W7 user stories working (web)
- [ ] Error states handled gracefully
- [ ] Loading states shown appropriately
- [ ] Both apps use same mock API
- [ ] Basic styling/theming applied
- [ ] Code follows project standards

---

*This is a living document. Update as you learn and iterate.*
