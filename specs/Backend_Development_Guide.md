# Backend Development Guide

**Project:** MunServ | **Version:** 1.0 | **Status:** Active

*Primary reference for backend API and database development. Start here.*

---

## 1. Development Philosophy

**Approach:** Test-Driven Development with Phase Gates

```
Write Tests → Implement → Refactor → Integrate → Commit (tests must pass) → Push
```

### 1.1 TDD Requirements by Layer

| Layer | TDD Strictness | Rationale |
|-------|---------------|-----------|
| Domain | Tests FIRST (strict) | Business rules must be provably correct |
| Service | Tests FIRST (strict) | Orchestration logic is critical |
| Repository | Tests after (integration) | SQL correctness via real database |
| Controller | Tests after (contract) | HTTP mapping, less logic |

### 1.2 Phase Gates

**Each phase must be complete before advancing:**

```
┌─────────────────────────────────────────────────────────────────┐
│  PHASE GATE CHECKLIST                                           │
├─────────────────────────────────────────────────────────────────┤
│  [ ] All unit tests pass                                        │
│  [ ] All integration tests pass                                 │
│  [ ] Coverage thresholds met (domain ≥80%, service ≥70%)       │
│  [ ] API endpoints match mock API contract                      │
│  [ ] ./gradlew build succeeds                                   │
│  [ ] Code reviewed (self or peer)                               │
│  [ ] Committed with conventional commit format                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Commit Rules

- **Tests MUST pass** before every commit
- **Integration tests MUST pass** before push
- Use conventional commits: `feat(backend): add issue state transition`
- No `--no-verify` or skipping hooks

---

## 2. Tech Stack & Dependencies

### 2.1 Core Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Language | Kotlin | 1.9.x |
| Framework | Spring Boot | 3.2.x |
| Build | Gradle (Kotlin DSL) | 8.x |
| JVM | Eclipse Temurin | 21 |
| Database | PostgreSQL + PostGIS | 15 + 3.3 |
| Cache | Redis | 7.x |
| Migration | Flyway | 10.x |
| Photo Storage | Local (dev) / R2 (prod) | - |

### 2.2 Gradle Dependencies

```kotlin
// backend/build.gradle.kts

plugins {
    kotlin("jvm") version "1.9.22"
    kotlin("plugin.spring") version "1.9.22"
    kotlin("plugin.jpa") version "1.9.22"
    id("org.springframework.boot") version "3.2.2"
    id("io.spring.dependency-management") version "1.1.4"
    id("org.jlleitschuh.gradle.ktlint") version "12.1.0"
}

java {
    sourceCompatibility = JavaVersion.VERSION_21
}

dependencies {
    // Spring Boot
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-data-redis")

    // Kotlin
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("org.jetbrains.kotlin:kotlin-reflect")

    // Database
    implementation("org.postgresql:postgresql")
    implementation("org.hibernate.orm:hibernate-spatial:6.4.2.Final")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")

    // JWT
    implementation("io.jsonwebtoken:jjwt-api:0.12.5")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.5")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.5")

    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("io.mockk:mockk:1.13.9")
    testImplementation("io.kotest:kotest-assertions-core:5.8.0")
    testImplementation("org.testcontainers:testcontainers:1.19.4")
    testImplementation("org.testcontainers:postgresql:1.19.4")
    testImplementation("org.testcontainers:junit-jupiter:1.19.4")
}

tasks.withType<Test> {
    useJUnitPlatform()
}

kotlin {
    compilerOptions {
        freeCompilerArgs.addAll("-Xjsr305=strict")
    }
}
```

### 2.3 Application Configuration

```yaml
# backend/src/main/resources/application.yml

spring:
  application:
    name: munserv-api

  datasource:
    url: jdbc:postgresql://localhost:5432/munserv_dev
    username: munserv
    password: munserv_dev
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.spatial.dialect.postgis.PostgisPG10Dialect
        format_sql: true
    show-sql: false

  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true

  data:
    redis:
      host: localhost
      port: 6379

server:
  port: 8080

jwt:
  secret: ${JWT_SECRET:dev-secret-key-change-in-production}
  access-token-expiry: 86400000    # 24 hours
  refresh-token-expiry: 7776000000 # 90 days
  temp-token-expiry: 600000        # 10 minutes

otp:
  expiry-seconds: 300  # 5 minutes
  length: 6
  log-to-console: true  # Development only

storage:
  type: local
  local:
    upload-dir: ./uploads
  r2:
    bucket: ${R2_BUCKET:munserv-photos-dev}
    access-key: ${R2_ACCESS_KEY:}
    secret-key: ${R2_SECRET_KEY:}
    endpoint: ${R2_ENDPOINT:}

management:
  endpoints:
    web:
      exposure:
        include: health,info
```

---

## 3. Project Structure

### 3.1 Directory Layout

```
backend/
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
├── gradlew
├── gradlew.bat
├── gradle/
│   └── wrapper/
├── src/
│   ├── main/
│   │   ├── kotlin/
│   │   │   └── com/munserv/
│   │   │       ├── MunServApplication.kt
│   │   │       ├── auth/
│   │   │       │   ├── api/
│   │   │       │   │   ├── AuthController.kt
│   │   │       │   │   ├── AuthRequest.kt
│   │   │       │   │   └── AuthResponse.kt
│   │   │       │   ├── domain/
│   │   │       │   │   ├── PhoneNumber.kt
│   │   │       │   │   ├── Pin.kt
│   │   │       │   │   └── AuthResult.kt
│   │   │       │   ├── service/
│   │   │       │   │   ├── AuthService.kt
│   │   │       │   │   ├── OtpService.kt
│   │   │       │   │   └── JwtService.kt
│   │   │       │   └── repository/
│   │   │       ├── members/
│   │   │       │   ├── api/
│   │   │       │   ├── domain/
│   │   │       │   │   ├── Member.kt
│   │   │       │   │   ├── MemberId.kt
│   │   │       │   │   └── MemberStatus.kt
│   │   │       │   ├── service/
│   │   │       │   └── repository/
│   │   │       │       ├── MemberRepository.kt
│   │   │       │       └── MemberEntity.kt
│   │   │       ├── issues/
│   │   │       │   ├── api/
│   │   │       │   │   ├── IssueController.kt
│   │   │       │   │   ├── IssueRequest.kt
│   │   │       │   │   └── IssueResponse.kt
│   │   │       │   ├── domain/
│   │   │       │   │   ├── Issue.kt
│   │   │       │   │   ├── IssueId.kt
│   │   │       │   │   ├── IssueType.kt
│   │   │       │   │   ├── IssueState.kt
│   │   │       │   │   └── IssueResult.kt
│   │   │       │   ├── service/
│   │   │       │   │   ├── IssueService.kt
│   │   │       │   │   └── HeatCalculationService.kt
│   │   │       │   └── repository/
│   │   │       │       ├── IssueRepository.kt
│   │   │       │       └── IssueEntity.kt
│   │   │       ├── sectors/
│   │   │       │   ├── api/
│   │   │       │   ├── domain/
│   │   │       │   ├── service/
│   │   │       │   └── repository/
│   │   │       ├── admin/
│   │   │       │   ├── api/
│   │   │       │   │   ├── AdminController.kt
│   │   │       │   │   └── AdminResponse.kt
│   │   │       │   └── service/
│   │   │       │       ├── DashboardService.kt
│   │   │       │       └── HeatReportService.kt
│   │   │       └── shared/
│   │   │           ├── config/
│   │   │           │   ├── JacksonConfig.kt
│   │   │           │   ├── WebConfig.kt
│   │   │           │   ├── SecurityConfig.kt
│   │   │           │   └── RedisConfig.kt
│   │   │           ├── security/
│   │   │           │   ├── JwtAuthenticationFilter.kt
│   │   │           │   └── JwtTokenProvider.kt
│   │   │           ├── api/
│   │   │           │   ├── ErrorResponse.kt
│   │   │           │   └── GlobalExceptionHandler.kt
│   │   │           └── types/
│   │   │               ├── GeoPoint.kt
│   │   │               └── Result.kt
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-local.yml
│   │       ├── application-test.yml
│   │       └── db/
│   │           └── migration/
│   │               ├── V001__create_enums.sql
│   │               ├── V002__create_pods_table.sql
│   │               └── ...
│   └── test/
│       ├── kotlin/
│       │   └── com/munserv/
│       │       ├── MunServApplicationTests.kt
│       │       ├── TestContainersConfig.kt
│       │       ├── auth/
│       │       │   ├── domain/
│       │       │   │   ├── PhoneNumberTest.kt
│       │       │   │   └── PinTest.kt
│       │       │   └── service/
│       │       │       └── AuthServiceTest.kt
│       │       ├── issues/
│       │       │   ├── domain/
│       │       │   │   ├── IssueStateTest.kt
│       │       │   │   └── IssueTest.kt
│       │       │   └── service/
│       │       │       └── IssueServiceTest.kt
│       │       └── integration/
│       │           ├── AuthApiContractTest.kt
│       │           ├── IssuesApiContractTest.kt
│       │           └── AdminApiContractTest.kt
│       └── resources/
│           ├── application-test.yml
│           └── seed-test-data.sql
└── CLAUDE.md
```

---

## 4. Database Schema

### 4.1 Migration Files

**V001__create_enums.sql**
```sql
-- Issue states with allowed transitions
CREATE TYPE issue_state AS ENUM (
    'reported',     -- Initial state
    'confirmed',    -- Verified by admin/community
    'in_progress',  -- Work started
    'fixed',        -- Resolved
    'rejected',     -- Invalid/spam
    'reopened'      -- Fix was inadequate
);

-- Issue type categories
CREATE TYPE issue_type AS ENUM (
    'pothole',
    'water_leak',
    'sewage_leak',
    'traffic_light',
    'street_light',
    'illegal_dumping',
    'graffiti',
    'other'
);

-- Member account status
CREATE TYPE member_status AS ENUM (
    'active',
    'pending',
    'suspended'
);

-- Admin role levels
CREATE TYPE admin_role AS ENUM (
    'sector_admin',
    'sector_chief',
    'pod_admin',
    'pod_chief'
);
```

**V002__create_pods_table.sql**
```sql
CREATE TABLE pods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pods_updated_at
    BEFORE UPDATE ON pods
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

**V003__create_sectors_table.sql**
```sql
CREATE TABLE sectors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pod_id UUID NOT NULL REFERENCES pods(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    center GEOGRAPHY(POINT, 4326) NOT NULL,
    boundary GEOGRAPHY(POLYGON, 4326),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_sectors_pod_name UNIQUE (pod_id, name)
);

CREATE INDEX idx_sectors_pod_id ON sectors(pod_id);
CREATE INDEX idx_sectors_center ON sectors USING GIST (center);
CREATE INDEX idx_sectors_boundary ON sectors USING GIST (boundary);

CREATE TRIGGER update_sectors_updated_at
    BEFORE UPDATE ON sectors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

**V004__create_members_table.sql**
```sql
CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE RESTRICT,
    phone_hash VARCHAR(64) NOT NULL,
    pin_hash VARCHAR(64) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    registration_location GEOGRAPHY(POINT, 4326) NOT NULL,
    status member_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT uq_members_phone_hash UNIQUE (phone_hash)
);

CREATE INDEX idx_members_sector_id ON members(sector_id);
CREATE INDEX idx_members_status ON members(status);
CREATE INDEX idx_members_registration_location ON members USING GIST (registration_location);

CREATE TRIGGER update_members_updated_at
    BEFORE UPDATE ON members
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

**V005__create_admins_table.sql**
```sql
CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE RESTRICT,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(64) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    role admin_role NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT uq_admins_email UNIQUE (email)
);

CREATE INDEX idx_admins_sector_id ON admins(sector_id);

CREATE TRIGGER update_admins_updated_at
    BEFORE UPDATE ON admins
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

**V006__create_issues_table.sql**
```sql
CREATE TABLE issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sector_id UUID NOT NULL REFERENCES sectors(id) ON DELETE RESTRICT,
    reporter_id UUID NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
    type issue_type NOT NULL,
    state issue_state NOT NULL DEFAULT 'reported',
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address TEXT,
    description TEXT,
    heat INTEGER NOT NULL DEFAULT 10,
    report_count INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_issues_sector_id ON issues(sector_id);
CREATE INDEX idx_issues_reporter_id ON issues(reporter_id);
CREATE INDEX idx_issues_state ON issues(state);
CREATE INDEX idx_issues_type ON issues(type);
CREATE INDEX idx_issues_location ON issues USING GIST (location);
CREATE INDEX idx_issues_heat ON issues(heat DESC);
CREATE INDEX idx_issues_sector_state ON issues(sector_id, state);
CREATE INDEX idx_issues_sector_heat ON issues(sector_id, heat DESC);
CREATE INDEX idx_issues_created_at ON issues(created_at DESC);

CREATE TRIGGER update_issues_updated_at
    BEFORE UPDATE ON issues
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

**V007__create_issue_photos_table.sql**
```sql
CREATE TABLE issue_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
    storage_key VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255),
    content_type VARCHAR(100),
    size_bytes BIGINT,
    captured_at TIMESTAMPTZ,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_issue_photos_issue_id ON issue_photos(issue_id);
```

**V008__create_issue_state_history_table.sql**
```sql
CREATE TABLE issue_state_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
    state issue_state NOT NULL,
    changed_by UUID REFERENCES admins(id),
    note TEXT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_issue_state_history_issue_id ON issue_state_history(issue_id);
CREATE INDEX idx_issue_state_history_changed_at ON issue_state_history(changed_at DESC);
```

**V009__seed_test_data.sql** (Development only)
```sql
-- Test pod
INSERT INTO pods (id, name) VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'Test Pod');

-- Test sector
INSERT INTO sectors (id, pod_id, name, center) VALUES
    ('550e8400-e29b-41d4-a716-446655440001',
     '550e8400-e29b-41d4-a716-446655440000',
     'Ward 42 - Northcliff',
     ST_MakePoint(27.9833, -26.1367)::geography);

-- Test admin (password: admin123)
INSERT INTO admins (id, sector_id, email, password_hash, display_name, role) VALUES
    ('550e8400-e29b-41d4-a716-446655440020',
     '550e8400-e29b-41d4-a716-446655440001',
     'admin@ward42.example.com',
     '$2a$10$N9qo8uLOickgx2ZMRZoMy.MQDq8xLzq5VpLGt8j0cH0xM.0g4q3Wi', -- bcrypt hash
     'Ward 42 Admin',
     'sector_admin');

-- Test members (PIN: 1234)
INSERT INTO members (id, sector_id, phone_hash, pin_hash, first_name, surname, address, registration_location) VALUES
    ('550e8400-e29b-41d4-a716-446655440010',
     '550e8400-e29b-41d4-a716-446655440001',
     'hash_of_+27821234567',
     '$2a$10$N9qo8uLOickgx2ZMRZoMy.MQDq8xLzq5VpLGt8j0cH0xM.0g4q3Wi',
     'John', 'Doe',
     '42 Doreen Road, Northcliff',
     ST_MakePoint(27.9800, -26.1350)::geography),
    ('550e8400-e29b-41d4-a716-446655440011',
     '550e8400-e29b-41d4-a716-446655440001',
     'hash_of_+27829876543',
     '$2a$10$N9qo8uLOickgx2ZMRZoMy.MQDq8xLzq5VpLGt8j0cH0xM.0g4q3Wi',
     'Sarah', 'Miller',
     '15 Doris Road, Northcliff',
     ST_MakePoint(27.9870, -26.1320)::geography);
```

---

## 5. API Contract

Base URL: `http://localhost:8080/api/v1`

### 5.1 Authentication Endpoints

#### POST /auth/register

Request OTP for phone number.

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

**Development:** OTP is logged to console, not sent via SMS.

---

#### POST /auth/verify-otp

Verify OTP code.

**Request:**
```json
{
  "phoneNumber": "+27821234567",
  "otp": "123456"
}
```

**Response (200) - New User:**
```json
{
  "status": "new_user",
  "tempToken": "temp-token-uuid"
}
```

**Response (200) - Existing User:**
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

---

#### POST /auth/complete-registration

Complete registration with profile and PIN.

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

---

#### POST /auth/login

Login with phone and PIN.

**Request:**
```json
{
  "phoneNumber": "+27821234567",
  "pin": "1234"
}
```

**Response (200):** Same as complete-registration response.

---

#### POST /auth/admin/login

Admin login with email and password.

**Request:**
```json
{
  "email": "admin@ward42.example.com",
  "password": "admin123"
}
```

**Response (200):**
```json
{
  "tokens": {
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG...",
    "expiresAt": "2025-01-15T10:30:00Z"
  },
  "profile": {
    "admin": {
      "id": "admin-uuid",
      "email": "admin@ward42.example.com",
      "displayName": "Ward 42 Admin",
      "sectorId": "sector-uuid",
      "role": "SECTOR_ADMIN"
    },
    "sector": { ... }
  }
}
```

---

#### POST /auth/refresh

Refresh tokens.

**Request:**
```json
{
  "refreshToken": "eyJhbG..."
}
```

**Response (200):**
```json
{
  "tokens": {
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG...",
    "expiresAt": "2025-01-15T10:30:00Z"
  }
}
```

---

### 5.2 Issues Endpoints

All require: `Authorization: Bearer {accessToken}`

#### GET /issues

List issues with filters.

**Query Parameters:**
| Param | Required | Default | Description |
|-------|----------|---------|-------------|
| sectorId | Yes | - | Filter by sector |
| state | No | all | Filter by state |
| type | No | all | Filter by type |
| page | No | 1 | Page number |
| limit | No | 20 | Items per page |
| sortBy | No | heat | `heat` or `createdAt` |

**Response (200):**
```json
{
  "items": [
    {
      "id": "issue-uuid",
      "type": "pothole",
      "state": "reported",
      "location": { "latitude": -26.1234, "longitude": 28.0123 },
      "heat": 75,
      "thumbnailUrl": "http://localhost:8080/uploads/photo-uuid.jpg",
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

---

#### GET /issues/{issueId}

Get issue details.

**Response (200):**
```json
{
  "id": "issue-uuid",
  "type": "pothole",
  "state": "confirmed",
  "location": { "latitude": -26.1234, "longitude": 28.0123 },
  "address": "123 Main Road, Northcliff",
  "description": "Large pothole near the traffic light",
  "heat": 75,
  "photoUrls": [
    "http://localhost:8080/uploads/photo1.jpg",
    "http://localhost:8080/uploads/photo2.jpg"
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
      "changedBy": null,
      "note": null
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

---

#### POST /issues

Create new issue (multipart form).

**Content-Type:** `multipart/form-data`

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
  "photoUrls": ["http://localhost:8080/uploads/photo.jpg"],
  "createdAt": "2025-01-15T09:00:00Z"
}
```

---

#### PATCH /issues/{issueId}/state

Update issue state (admin only).

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

---

#### GET /issues/mine

Get current user's reported issues.

**Query Parameters:**
| Param | Default | Description |
|-------|---------|-------------|
| page | 1 | Page number |
| limit | 20 | Items per page |

**Response (200):** Same format as GET /issues.

---

### 5.3 Sectors Endpoints

#### GET /sectors

List all sectors.

**Response (200):**
```json
{
  "items": [
    {
      "id": "sector-uuid-1",
      "name": "Ward 42 - Northcliff",
      "center": { "latitude": -26.1367, "longitude": 27.9833 }
    }
  ]
}
```

---

### 5.4 Admin Endpoints

All require admin role in JWT.

#### GET /admin/dashboard

Get dashboard statistics.

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

---

#### GET /admin/reports/heat

Get issues ranked by heat.

**Query Parameters:**
| Param | Default | Description |
|-------|---------|-------------|
| limit | 20 | Max items to return |

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
      "thumbnailUrl": "http://localhost:8080/uploads/photo.jpg"
    }
  ]
}
```

---

#### GET /admin/members

Get sector members list.

**Query Parameters:**
| Param | Default | Description |
|-------|---------|-------------|
| page | 1 | Page number |
| limit | 20 | Items per page |

**Response (200):**
```json
{
  "items": [
    {
      "id": "member-uuid",
      "firstName": "John",
      "surname": "Doe",
      "phoneNumber": "+27821234567",
      "address": "42 Doreen Road, Northcliff",
      "status": "active",
      "issueCount": 5,
      "joinedAt": "2025-01-10T08:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalItems": 2,
    "totalPages": 1
  }
}
```

---

### 5.5 Error Response Format

All errors follow this structure:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "details": { "field": "...", "reason": "..." }
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
| 409 | CONFLICT | Already exists |
| 422 | INVALID_STATE_TRANSITION | Can't change state that way |
| 500 | INTERNAL_ERROR | Server error |

---

## 6. Data Shapes (Kotlin)

### 6.1 Value Objects

```kotlin
// Type-safe IDs - prevents mixing issue_id with sector_id
@JvmInline
value class IssueId(val value: UUID) {
    override fun toString(): String = value.toString()
}

@JvmInline
value class SectorId(val value: UUID) {
    override fun toString(): String = value.toString()
}

@JvmInline
value class MemberId(val value: UUID) {
    override fun toString(): String = value.toString()
}

@JvmInline
value class AdminId(val value: UUID) {
    override fun toString(): String = value.toString()
}

@JvmInline
value class PodId(val value: UUID) {
    override fun toString(): String = value.toString()
}
```

```kotlin
// Phone number with E.164 validation
@JvmInline
value class PhoneNumber private constructor(val value: String) {
    companion object {
        private val E164_REGEX = Regex("^\\+[1-9]\\d{1,14}$")

        fun of(value: String): Result<PhoneNumber> =
            if (E164_REGEX.matches(value)) {
                Result.success(PhoneNumber(value))
            } else {
                Result.failure(IllegalArgumentException("Invalid E.164 phone format"))
            }

        fun ofUnsafe(value: String): PhoneNumber = PhoneNumber(value)
    }
}

// PIN validation (4-6 digits)
@JvmInline
value class Pin private constructor(val value: String) {
    companion object {
        private val PIN_REGEX = Regex("^\\d{4,6}$")

        fun of(value: String): Result<Pin> =
            if (PIN_REGEX.matches(value)) {
                Result.success(Pin(value))
            } else {
                Result.failure(IllegalArgumentException("PIN must be 4-6 digits"))
            }
    }
}
```

```kotlin
// Geography point
data class GeoPoint(
    val latitude: Double,
    val longitude: Double
) {
    init {
        require(latitude in -90.0..90.0) { "Latitude must be between -90 and 90" }
        require(longitude in -180.0..180.0) { "Longitude must be between -180 and 180" }
    }
}
```

### 6.2 Enums and Sealed Classes

```kotlin
enum class IssueType {
    POTHOLE,
    WATER_LEAK,
    SEWAGE_LEAK,
    TRAFFIC_LIGHT,
    STREET_LIGHT,
    ILLEGAL_DUMPING,
    GRAFFITI,
    OTHER;

    fun toApiString(): String = name.lowercase()

    companion object {
        fun fromApiString(value: String): IssueType =
            valueOf(value.uppercase())
    }
}
```

```kotlin
// Sealed class with state transition rules
sealed class IssueState(val value: String) {
    object Reported : IssueState("reported")
    object Confirmed : IssueState("confirmed")
    object InProgress : IssueState("in_progress")
    object Fixed : IssueState("fixed")
    object Rejected : IssueState("rejected")
    object Reopened : IssueState("reopened")

    fun allowedTransitions(): Set<IssueState> = when (this) {
        Reported -> setOf(Confirmed, Rejected)
        Confirmed -> setOf(InProgress, Rejected)
        InProgress -> setOf(Fixed, Rejected)
        Fixed -> setOf(Reopened)
        Rejected -> emptySet()
        Reopened -> setOf(Confirmed)
    }

    fun canTransitionTo(newState: IssueState): Boolean =
        newState in allowedTransitions()

    companion object {
        fun fromString(value: String): IssueState = when (value.lowercase()) {
            "reported" -> Reported
            "confirmed" -> Confirmed
            "in_progress" -> InProgress
            "fixed" -> Fixed
            "rejected" -> Rejected
            "reopened" -> Reopened
            else -> throw IllegalArgumentException("Unknown state: $value")
        }
    }
}
```

```kotlin
enum class MemberStatus {
    ACTIVE,
    PENDING,
    SUSPENDED;

    fun toApiString(): String = name.lowercase()
}

enum class AdminRole {
    SECTOR_ADMIN,
    SECTOR_CHIEF,
    POD_ADMIN,
    POD_CHIEF;

    fun toApiString(): String = name.uppercase()
}
```

### 6.3 Domain Entities

```kotlin
// Pure domain entity - no JPA annotations
data class Issue(
    val id: IssueId,
    val sectorId: SectorId,
    val reporterId: MemberId,
    val type: IssueType,
    val state: IssueState,
    val location: GeoPoint,
    val address: String?,
    val description: String?,
    val heat: Int,
    val reportCount: Int,
    val createdAt: Instant,
    val updatedAt: Instant
) {
    fun canTransitionTo(newState: IssueState): Boolean =
        state.canTransitionTo(newState)

    fun withState(newState: IssueState): Issue =
        copy(state = newState, updatedAt = Instant.now())

    fun withHeat(newHeat: Int): Issue =
        copy(heat = newHeat)
}
```

```kotlin
data class Member(
    val id: MemberId,
    val sectorId: SectorId,
    val phoneNumber: PhoneNumber,
    val firstName: String,
    val surname: String,
    val address: String,
    val registrationLocation: GeoPoint,
    val status: MemberStatus,
    val createdAt: Instant,
    val updatedAt: Instant
) {
    val displayName: String get() = "$firstName ${surname.first()}."
}
```

```kotlin
data class Sector(
    val id: SectorId,
    val podId: PodId,
    val name: String,
    val center: GeoPoint,
    val createdAt: Instant
)
```

```kotlin
data class Admin(
    val id: AdminId,
    val sectorId: SectorId,
    val email: String,
    val displayName: String,
    val role: AdminRole,
    val createdAt: Instant
)
```

### 6.4 Sealed Results

```kotlin
// Generic Result interface
sealed interface Result<out T> {
    data class Success<T>(val value: T) : Result<T>
    data class Failure(val error: DomainError) : Result<Nothing>
}

sealed interface DomainError {
    data class NotFound(val type: String, val id: String) : DomainError
    data class ValidationError(val errors: List<String>) : DomainError
    data class Unauthorized(val reason: String) : DomainError
    data class Conflict(val reason: String) : DomainError
}
```

```kotlin
// Issue-specific results
sealed interface IssueResult {
    data class Success(val issue: Issue) : IssueResult
    data class NotFound(val id: IssueId) : IssueResult
    data class InvalidTransition(val from: IssueState, val to: IssueState) : IssueResult
    data class ValidationError(val errors: List<String>) : IssueResult
    data class Unauthorized(val reason: String) : IssueResult
}
```

```kotlin
// Auth-specific results
sealed interface AuthResult {
    data class NewUser(val tempToken: String) : AuthResult
    data class ExistingUser(val tokens: AuthTokens, val profile: MemberProfile) : AuthResult
    data class AdminLogin(val tokens: AuthTokens, val profile: AdminProfile) : AuthResult
    data class InvalidOtp(val message: String) : AuthResult
    data class InvalidCredentials(val message: String) : AuthResult
    data class PhoneNotRegistered(val phone: String) : AuthResult
}

data class AuthTokens(
    val accessToken: String,
    val refreshToken: String,
    val expiresAt: Instant
)

data class MemberProfile(
    val member: Member,
    val sector: Sector
)

data class AdminProfile(
    val admin: Admin,
    val sector: Sector
)
```

---

## 7. Implementation Phases

### Phase 0: Project Scaffold

**Goal:** Spring Boot project compiles, runs, and passes health check.

**Files to Create:**

```
backend/
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
├── src/main/kotlin/com/munserv/
│   ├── MunServApplication.kt
│   └── shared/
│       ├── config/
│       │   ├── JacksonConfig.kt
│       │   └── WebConfig.kt
│       ├── api/
│       │   ├── ErrorResponse.kt
│       │   └── GlobalExceptionHandler.kt
│       └── types/
│           └── GeoPoint.kt
├── src/main/resources/
│   ├── application.yml
│   └── application-test.yml
└── src/test/kotlin/com/munserv/
    ├── MunServApplicationTests.kt
    └── TestContainersConfig.kt
```

**Tests to Write FIRST:**
1. `GeoPointTest.kt` - Validate latitude/longitude bounds
2. `MunServApplicationTests.kt` - Context loads

**Exit Criteria:**
- [ ] `./gradlew build` passes
- [ ] `./gradlew bootRun` starts on port 8080
- [ ] `GET /actuator/health` returns 200
- [ ] TestContainers integration works

---

### Phase 1: Database Foundation

**Goal:** Core schema with sectors endpoint working.

**Migrations:**
- V001__create_enums.sql
- V002__create_pods_table.sql
- V003__create_sectors_table.sql

**Files to Create:**

```
backend/src/main/kotlin/com/munserv/
├── sectors/
│   ├── api/
│   │   ├── SectorController.kt
│   │   └── SectorResponse.kt
│   ├── domain/
│   │   ├── Sector.kt
│   │   └── SectorId.kt
│   ├── service/
│   │   └── SectorService.kt
│   └── repository/
│       ├── SectorRepository.kt
│       ├── JpaSectorRepository.kt
│       └── SectorEntity.kt
└── shared/types/
    ├── PodId.kt
    └── SectorId.kt
```

**Tests to Write FIRST:**
1. `SectorIdTest.kt` - Value object tests
2. `SectorTest.kt` - Domain entity tests (if any logic)

**Tests After Implementation:**
1. `SectorRepositoryTest.kt` - Integration test with TestContainers
2. `SectorControllerTest.kt` - API contract test

**Exit Criteria:**
- [ ] Flyway runs migrations on startup
- [ ] `GET /api/v1/sectors` returns sectors list
- [ ] Repository integration test passes

---

### Phase 2: Authentication

**Goal:** Full authentication flow with JWT.

**Migrations:**
- V004__create_members_table.sql
- V005__create_admins_table.sql

**Files to Create:**

```
backend/src/main/kotlin/com/munserv/
├── auth/
│   ├── api/
│   │   ├── AuthController.kt
│   │   ├── AuthRequest.kt
│   │   └── AuthResponse.kt
│   ├── domain/
│   │   ├── PhoneNumber.kt
│   │   ├── Pin.kt
│   │   └── AuthResult.kt
│   └── service/
│       ├── AuthService.kt
│       ├── OtpService.kt
│       └── JwtService.kt
├── members/
│   ├── domain/
│   │   ├── Member.kt
│   │   ├── MemberId.kt
│   │   └── MemberStatus.kt
│   ├── service/
│   │   └── MemberService.kt
│   └── repository/
│       ├── MemberRepository.kt
│       └── MemberEntity.kt
└── shared/
    ├── config/
    │   ├── SecurityConfig.kt
    │   └── RedisConfig.kt
    └── security/
        ├── JwtAuthenticationFilter.kt
        └── JwtTokenProvider.kt
```

**Tests to Write FIRST (Domain TDD):**
1. `PhoneNumberTest.kt` - E.164 validation
2. `PinTest.kt` - 4-6 digit validation
3. `MemberTest.kt` - Member creation
4. `MemberStatusTest.kt` - Status enum

**Tests to Write FIRST (Service TDD):**
1. `AuthServiceTest.kt` - Registration flow, login flow
2. `OtpServiceTest.kt` - OTP generation and validation
3. `JwtServiceTest.kt` - Token generation and parsing

**Integration Tests:**
1. `AuthApiContractTest.kt` - All auth endpoints

**Exit Criteria:**
- [ ] All domain tests pass
- [ ] All service tests pass
- [ ] Can register new member via API (OTP logged to console)
- [ ] Can login and receive JWT
- [ ] Protected endpoints reject unauthenticated requests
- [ ] Admin login works

---

### Phase 3: Issues Domain

**Goal:** Issue CRUD with state machine.

**Migrations:**
- V006__create_issues_table.sql
- V007__create_issue_photos_table.sql
- V008__create_issue_state_history_table.sql

**Files to Create:**

```
backend/src/main/kotlin/com/munserv/
└── issues/
    ├── api/
    │   ├── IssueController.kt
    │   ├── IssueRequest.kt
    │   └── IssueResponse.kt
    ├── domain/
    │   ├── Issue.kt
    │   ├── IssueId.kt
    │   ├── IssueType.kt
    │   ├── IssueState.kt
    │   ├── IssueResult.kt
    │   └── StateHistoryEntry.kt
    ├── service/
    │   ├── IssueService.kt
    │   └── HeatCalculationService.kt
    └── repository/
        ├── IssueRepository.kt
        ├── JpaIssueRepository.kt
        ├── IssueEntity.kt
        └── StateHistoryEntity.kt
```

**Tests to Write FIRST (Domain TDD - STRICT):**
1. `IssueStateTest.kt` - ALL state transitions
   - reported → confirmed ✓
   - reported → rejected ✓
   - reported → fixed ✗
   - confirmed → in_progress ✓
   - ... (test all valid and invalid)
2. `IssueTest.kt` - `canTransitionTo()`, `withState()`
3. `IssueTypeTest.kt` - Enum mapping

**Tests to Write FIRST (Service TDD):**
1. `IssueServiceTest.kt` - Create, find, update state
2. `HeatCalculationServiceTest.kt` - Heat formula

**Integration Tests:**
1. `IssueRepositoryTest.kt` - Spatial queries
2. `IssuesApiContractTest.kt` - All issue endpoints

**Exit Criteria:**
- [ ] All state transition tests pass
- [ ] All service tests pass
- [ ] Issue CRUD works via API
- [ ] Invalid state transitions are rejected with 422
- [ ] State history is recorded

---

### Phase 4: Admin Endpoints

**Goal:** Dashboard, heat report, members list.

**Files to Create:**

```
backend/src/main/kotlin/com/munserv/
└── admin/
    ├── api/
    │   ├── AdminController.kt
    │   └── AdminResponse.kt
    └── service/
        ├── DashboardService.kt
        └── HeatReportService.kt
```

**Tests to Write FIRST (Service TDD):**
1. `DashboardServiceTest.kt` - Stats aggregation
2. `HeatReportServiceTest.kt` - Heat sorting

**Integration Tests:**
1. `AdminApiContractTest.kt` - All admin endpoints

**Exit Criteria:**
- [ ] Dashboard returns correct aggregated stats
- [ ] Heat report sorted by heat descending
- [ ] Members list includes issue counts
- [ ] All endpoints require admin role

---

### Phase 5: Photo Upload

**Goal:** Photo upload with local storage.

**Files to Create:**

```
backend/src/main/kotlin/com/munserv/
├── photos/
│   ├── domain/
│   │   ├── PhotoId.kt
│   │   ├── StorageKey.kt
│   │   └── UploadResult.kt
│   ├── service/
│   │   ├── PhotoStorageService.kt
│   │   ├── LocalPhotoStorageService.kt
│   │   └── PhotoValidationService.kt
│   └── repository/
│       ├── IssuePhotoRepository.kt
│       └── IssuePhotoEntity.kt
└── shared/config/
    └── StorageConfig.kt
```

**Tests to Write FIRST:**
1. `PhotoValidationServiceTest.kt` - File type, size validation
2. `LocalPhotoStorageServiceTest.kt` - Upload, serve

**Exit Criteria:**
- [ ] Photos upload to local storage
- [ ] Issue responses include photo URLs
- [ ] Invalid file types rejected (400)
- [ ] File size limits enforced (5MB)

---

### Phase 6: Integration Testing

**Goal:** API matches mock API exactly.

**Tests to Create:**

```
backend/src/test/kotlin/com/munserv/integration/
├── AuthApiContractTest.kt
├── IssuesApiContractTest.kt
├── SectorsApiContractTest.kt
├── AdminApiContractTest.kt
└── scenarios/
    ├── MemberRegistrationScenarioTest.kt
    ├── IssueReportingScenarioTest.kt
    └── AdminWorkflowScenarioTest.kt
```

**Seed Data:**
- V009__seed_test_data.sql

**Exit Criteria:**
- [ ] All API responses match mock API contract exactly
- [ ] All E2E scenario tests pass
- [ ] Mobile app works against real backend
- [ ] Web app works against real backend

---

### Phase 7: Hardening

**Goal:** Production ready.

**Security:**
- Rate limiting on auth endpoints
- Account lockout after 5 failed attempts
- Security headers

**Performance:**
- Redis caching for dashboard stats
- Query optimization
- Connection pool tuning

**Exit Criteria:**
- [ ] Rate limiting works (5 requests/minute on auth)
- [ ] Account lockout after failures
- [ ] Security headers present
- [ ] Dashboard uses Redis cache

---

## 8. Testing Patterns

### 8.1 Domain Unit Test (TDD First)

```kotlin
// Write this BEFORE implementing IssueState
class IssueStateTest {
    @Test
    fun `reported can transition to confirmed`() {
        val state = IssueState.Reported
        state.canTransitionTo(IssueState.Confirmed) shouldBe true
    }

    @Test
    fun `reported cannot transition to fixed`() {
        val state = IssueState.Reported
        state.canTransitionTo(IssueState.Fixed) shouldBe false
    }

    @Test
    fun `rejected cannot transition to anything`() {
        val state = IssueState.Rejected
        state.allowedTransitions() shouldBe emptySet()
    }
}
```

### 8.2 Service Unit Test (TDD First)

```kotlin
// Write this BEFORE implementing IssueService
class IssueServiceTest {
    private val repository = mockk<IssueRepository>()
    private val heatService = mockk<HeatCalculationService>()
    private val service = IssueService(repository, heatService)

    @Test
    fun `updateState returns NotFound when issue does not exist`() {
        // Arrange
        val id = IssueId(UUID.randomUUID())
        every { repository.findById(id) } returns null

        // Act
        val result = service.updateState(id, IssueState.Confirmed, mockAdminId)

        // Assert
        result shouldBe IssueResult.NotFound(id)
    }

    @Test
    fun `updateState returns InvalidTransition for illegal state change`() {
        // Arrange
        val issue = createTestIssue(state = IssueState.Reported)
        every { repository.findById(issue.id) } returns issue

        // Act
        val result = service.updateState(issue.id, IssueState.Fixed, mockAdminId)

        // Assert
        result shouldBe IssueResult.InvalidTransition(
            IssueState.Reported,
            IssueState.Fixed
        )
    }
}
```

### 8.3 Repository Integration Test

```kotlin
@DataJpaTest
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class IssueRepositoryTest {
    companion object {
        @Container
        val postgres = PostgreSQLContainer("postgis/postgis:15-3.3")
            .withDatabaseName("test")
            .withUsername("test")
            .withPassword("test")
    }

    @DynamicPropertySource
    @JvmStatic
    fun configureProperties(registry: DynamicPropertyRegistry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl)
        registry.add("spring.datasource.username", postgres::getUsername)
        registry.add("spring.datasource.password", postgres::getPassword)
    }

    @Autowired
    lateinit var repository: IssueRepository

    @Test
    fun `findBySectorId returns issues in sector`() {
        // Arrange - seed data via Flyway

        // Act
        val issues = repository.findBySectorId(testSectorId)

        // Assert
        issues shouldHaveSize 5
    }
}
```

### 8.4 Controller Integration Test

```kotlin
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class IssuesApiContractTest {
    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var jwtService: JwtService

    @Test
    fun `GET issues returns paginated list`() {
        val token = jwtService.generateAccessToken(testMemberId)

        mockMvc.get("/api/v1/issues") {
            header("Authorization", "Bearer $token")
            param("sectorId", testSectorId.toString())
        }.andExpect {
            status { isOk() }
            jsonPath("$.items") { isArray() }
            jsonPath("$.pagination.page") { value(1) }
            jsonPath("$.pagination.limit") { value(20) }
        }
    }

    @Test
    fun `PATCH issue state returns 422 for invalid transition`() {
        val token = jwtService.generateAdminToken(testAdminId)

        mockMvc.patch("/api/v1/issues/$reportedIssueId/state") {
            header("Authorization", "Bearer $token")
            contentType = MediaType.APPLICATION_JSON
            content = """{"state": "fixed", "note": "test"}"""
        }.andExpect {
            status { isUnprocessableEntity() }
            jsonPath("$.error.code") { value("INVALID_STATE_TRANSITION") }
        }
    }
}
```

### 8.5 Test Fixtures

```kotlin
// Create in test/kotlin/com/munserv/fixtures/
object IssueFixtures {
    fun reported(
        id: IssueId = IssueId(UUID.randomUUID()),
        sectorId: SectorId = TestData.SECTOR_ID
    ) = Issue(
        id = id,
        sectorId = sectorId,
        reporterId = TestData.MEMBER_ID,
        type = IssueType.POTHOLE,
        state = IssueState.Reported,
        location = GeoPoint(-26.1350, 27.9800),
        address = "Test Address",
        description = null,
        heat = 10,
        reportCount = 1,
        createdAt = Instant.now(),
        updatedAt = Instant.now()
    )

    fun confirmed() = reported().copy(state = IssueState.Confirmed)
    fun inProgress() = confirmed().copy(state = IssueState.InProgress)
}

object TestData {
    val POD_ID = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))
    val SECTOR_ID = SectorId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    val MEMBER_ID = MemberId(UUID.fromString("550e8400-e29b-41d4-a716-446655440010"))
    val ADMIN_ID = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440020"))
}
```

---

## 9. Development Workflow

### 9.1 Daily Development

```bash
# 1. Start services
cd infrastructure/docker
docker compose up -d

# 2. Run backend (new terminal)
cd backend
./gradlew bootRun

# 3. Verify health
curl http://localhost:8080/actuator/health

# 4. Run tests before committing
./gradlew test

# 5. Commit (only if tests pass)
git add .
git commit -m "feat(backend): add issue state validation"
```

### 9.2 TDD Workflow

```bash
# 1. Write failing test
./gradlew test --tests "*IssueStateTest*"
# FAIL - IssueState doesn't exist

# 2. Implement minimum code to pass
# ... create IssueState.kt

./gradlew test --tests "*IssueStateTest*"
# PASS

# 3. Refactor while green
# ... clean up code

./gradlew test --tests "*IssueStateTest*"
# STILL PASS

# 4. Commit
git add .
git commit -m "feat(backend): add IssueState with transitions"
```

### 9.3 Build Commands

```bash
# Full build (compile + test + lint)
./gradlew build

# Run tests only
./gradlew test

# Run specific test class
./gradlew test --tests "*IssueStateTest*"

# Start dev server
./gradlew bootRun

# Lint check
./gradlew ktlintCheck

# Auto-fix lint issues
./gradlew ktlintFormat

# Clean build
./gradlew clean build
```

### 9.4 Database Commands

```bash
# Start PostgreSQL + Redis
cd infrastructure/docker
docker compose up -d postgres redis

# Connect to database
docker exec -it munserv-db psql -U munserv -d munserv_dev

# Reset database (recreate)
docker compose down -v
docker compose up -d

# View migration status
docker exec -it munserv-db psql -U munserv -d munserv_dev \
  -c "SELECT * FROM flyway_schema_history;"
```

---

## 10. Checklists

### 10.1 Phase Completion Checklist

```
[ ] All unit tests pass (./gradlew test)
[ ] Coverage thresholds met
    [ ] Domain ≥ 80%
    [ ] Service ≥ 70%
    [ ] Repository ≥ 60%
    [ ] Controller ≥ 50%
[ ] Integration tests pass
[ ] API responses match mock API contract
[ ] Lint passes (./gradlew ktlintCheck)
[ ] Full build succeeds (./gradlew build)
[ ] Code reviewed
[ ] Committed with conventional commit
```

### 10.2 Before Push Checklist

```
[ ] All tests pass locally
[ ] No console.log/print debugging
[ ] No hardcoded secrets
[ ] Migrations are immutable (if on main)
[ ] API contract unchanged (or documented)
```

### 10.3 Phase 0 Complete Checklist

```
[ ] build.gradle.kts compiles
[ ] ./gradlew bootRun starts server on 8080
[ ] /actuator/health returns 200
[ ] TestContainers works with PostgreSQL + PostGIS
[ ] GeoPoint tests pass
```

### 10.4 Phase 2 Complete Checklist

```
[ ] Can POST /auth/register (OTP logged to console)
[ ] Can POST /auth/verify-otp (new_user or existing_user)
[ ] Can POST /auth/complete-registration
[ ] Can POST /auth/login (receive JWT)
[ ] Can POST /auth/admin/login
[ ] Can POST /auth/refresh
[ ] Protected endpoints reject unauthenticated requests (401)
[ ] All auth domain tests pass
[ ] All auth service tests pass
```

### 10.5 Phase 3 Complete Checklist

```
[ ] All IssueState transition tests pass
[ ] All IssueService tests pass
[ ] Can GET /api/v1/issues (with filters, pagination)
[ ] Can GET /api/v1/issues/{id}
[ ] Can POST /api/v1/issues (creates issue)
[ ] Can PATCH /api/v1/issues/{id}/state (admin only)
[ ] Can GET /api/v1/issues/mine
[ ] Invalid state transitions return 422
[ ] State history is recorded
```

### 10.6 Full MVP Complete Checklist

```
[ ] All Phase 0-7 checklists complete
[ ] All API endpoints match mock API contract
[ ] Mobile app works against real backend
[ ] Web app works against real backend
[ ] No regressions from mock API behavior
[ ] Rate limiting works
[ ] Security headers present
[ ] Ready for staging deployment
```

---

## 11. Quick Reference

### API Endpoints Summary

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /auth/register | No | Request OTP |
| POST | /auth/verify-otp | No | Verify OTP |
| POST | /auth/complete-registration | Temp | Complete registration |
| POST | /auth/login | No | Login with PIN |
| POST | /auth/admin/login | No | Admin login |
| POST | /auth/refresh | No | Refresh tokens |
| GET | /sectors | Member | List sectors |
| GET | /issues | Member | List issues |
| GET | /issues/{id} | Member | Get issue details |
| POST | /issues | Member | Create issue |
| GET | /issues/mine | Member | My issues |
| PATCH | /issues/{id}/state | Admin | Update state |
| GET | /admin/dashboard | Admin | Dashboard stats |
| GET | /admin/reports/heat | Admin | Heat report |
| GET | /admin/members | Admin | Members list |

### Issue State Transitions

```
Reported → Confirmed | Rejected
Confirmed → InProgress | Rejected
InProgress → Fixed | Rejected
Fixed → Reopened
Reopened → Confirmed
Rejected → (terminal)
```

### Test Credentials

| Type | Credential | Value |
|------|------------|-------|
| Member Phone | +27821234567 | |
| Member OTP | 123456 | (logged to console) |
| Member PIN | 1234 | |
| Admin Email | admin@ward42.example.com | |
| Admin Password | admin123 | |

---

*This is a living document. Update as you progress through implementation.*
