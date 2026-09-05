# Technology Stack Selection

**Project:** Municipal Service Issue Tracker (MunServ)  
**Version:** 1.0  
**Last Updated:** December 2025  
**Status:** Approved

---

## 1. Overview

This document defines the technology choices for the MunServ system. Selections were made based on:
- Open source friendliness
- Developer availability and community support
- Cost-effectiveness for community-funded projects
- Scalability from small rural pods to large metro deployments
- Future extensibility (AI integration, offline support)

---

## 2. Technology Stack Summary

| Layer | Technology | Language |
|-------|------------|----------|
| Mobile App | Flutter | Dart |
| Web Admin | React | TypeScript |
| Backend API | Spring Boot | Kotlin |
| Database | PostgreSQL + PostGIS | SQL |
| Photo Storage | Cloudflare R2 | - |
| Cloud Hosting | DigitalOcean | - |
| API Style | REST | JSON |

---

## 3. Mobile Application

### Selected: Flutter (Dart)

**Why Flutter:**
- Single codebase for Android and iOS
- Compiles to native ARM code (near-native performance)
- Excellent for photo-heavy apps with maps
- Strong community and growing SA developer base
- Hot reload for fast development
- Beautiful, customizable UI components

**Key Libraries (anticipated):**
| Purpose | Library |
|---------|---------|
| State management | Riverpod or Bloc |
| HTTP client | Dio |
| Local storage | Hive or SharedPreferences |
| Maps | google_maps_flutter or flutter_map |
| Camera | camera + image_picker |
| Biometric auth | local_auth |
| Push notifications | firebase_messaging |

**Alternatives Considered:**
| Option | Why Not Selected |
|--------|------------------|
| Kotlin + Swift (native) | Double codebase, double maintenance |
| React Native | Slightly lower performance, bridge overhead |
| Kotlin Multiplatform | Still maturing, smaller community |

---

## 4. Web Administration Application

### Selected: React (TypeScript)

**Why React:**
- Largest frontend ecosystem
- Extensive component libraries available
- Easy to find developers and resources
- TypeScript adds type safety and better tooling
- Pairs well with REST APIs

**Key Libraries (anticipated):**
| Purpose | Library |
|---------|---------|
| UI Components | shadcn/ui or Ant Design |
| State management | React Query + Zustand |
| Routing | React Router |
| Forms | React Hook Form |
| Maps | Leaflet or Mapbox GL |
| Charts/Reports | Recharts or Chart.js |
| HTTP client | Axios or fetch |

**Build Tooling:** Vite (fast, modern)

---

## 5. Backend API

### Selected: Spring Boot (Kotlin)

**Why Spring Boot with Kotlin:**
- Enterprise-grade reliability and security
- Kotlin is concise, null-safe, and modern
- Excellent ecosystem for building REST APIs
- Strong support for PostgreSQL and geospatial data
- Good testing frameworks
- Large community and long-term support

**Key Dependencies (anticipated):**
| Purpose | Library/Module |
|---------|----------------|
| Web framework | Spring Web |
| Database access | Spring Data JPA |
| Security | Spring Security |
| Validation | Jakarta Validation |
| API documentation | SpringDoc OpenAPI |
| Geospatial | Hibernate Spatial |
| Cloud storage | AWS SDK (S3-compatible for R2) |
| SMS/OTP | Twilio SDK or Africa's Talking |

**Project Structure:**
```
src/main/kotlin/
├── config/          # Security, CORS, app config
├── controller/      # REST endpoints
├── service/         # Business logic
├── repository/      # Database access
├── model/           # Entities and DTOs
├── security/        # Auth, JWT handling
└── util/            # Helpers, extensions
```

**Alternatives Considered:**
| Option | Why Not Selected |
|--------|------------------|
| FastAPI (Python) | Developer preference for Kotlin |
| Express (Node.js) | Less structured, typing weaker |
| ASP.NET Core | Less common in open source |

---

## 6. Database

### Selected: PostgreSQL + PostGIS

**Why PostgreSQL:**
- Rock-solid reliability and data integrity
- Excellent for relational data (users, roles, issues, states)
- Free and open source
- Scales well from small to large deployments
- Strong community and tooling

**Why PostGIS Extension:**
- Native geospatial queries ("find issues within this polygon")
- Efficient spatial indexing
- Handles sector boundary definitions
- Distance calculations for "issues near me"

**Example Geospatial Queries:**
```sql
-- Find all issues within a sector boundary
SELECT * FROM issues 
WHERE ST_Within(location, (SELECT boundary FROM sectors WHERE id = ?));

-- Find issues within 500m of a point
SELECT * FROM issues 
WHERE ST_DWithin(location, ST_MakePoint(lng, lat)::geography, 500);
```

**Version:** PostgreSQL 15+ with PostGIS 3.3+

**Alternatives Considered:**
| Option | Why Not Selected |
|--------|------------------|
| MySQL/MariaDB | Weaker geospatial support |
| MongoDB | Less data integrity, overkill flexibility |

---

## 7. Photo Storage

### Selected: Cloudflare R2

**Why R2:**
- **No egress fees** - critical for photo-heavy app
- S3-compatible API (industry standard)
- Global CDN included
- Very cost-effective at scale
- Easy to integrate with any backend

**Pricing Advantage:**
| Provider | Storage (10GB) | Egress (100GB/month) |
|----------|----------------|----------------------|
| Cloudflare R2 | ~$0.15/month | $0 |
| AWS S3 | ~$0.23/month | ~$9/month |
| DigitalOcean Spaces | $5/month min | ~$10/month |

**Photo Handling Strategy:**
1. Mobile app compresses photo before upload
2. Backend receives photo, generates unique key
3. Backend uploads to R2, stores URL in database
4. Photos served directly from R2 CDN

**Folder Structure in R2:**
```
/{pod_id}/
  /{sector_id}/
    /{issue_id}/
      /{photo_id}.jpg
      /{photo_id}_thumb.jpg
```

---

## 8. Cloud Hosting

### Selected: DigitalOcean (Initial Deployment)

**Why DigitalOcean:**
- Simple, predictable pricing
- Easy to set up and manage
- Managed PostgreSQL available
- App Platform for backend deployment
- Good documentation
- Easy migration path to AWS/Azure later if needed

**Initial Setup (Small Pod):**
| Component | DO Service | Estimated Cost |
|-----------|------------|----------------|
| Backend API | App Platform (Basic) | $12/month |
| Database | Managed PostgreSQL (Basic) | $15/month |
| **Total** | | **~$27/month** |

**Scaling Path:**
- Small pod (< 1000 users): Basic tier
- Medium pod (1000-10000 users): Professional tier
- Large metro pod: Consider AWS/Azure with auto-scaling

**Alternatives Considered:**
| Option | Why Not Selected (for MVP) |
|--------|----------------------------|
| AWS | Complex, costs can spiral unpredictably |
| Azure | Complex for small deployments |
| Hetzner | Smaller ecosystem, less managed services |

---

## 9. API Design

### Selected: REST (JSON)

**Why REST:**
- Simple and well-understood
- Perfect fit for this use case (CRUD operations on issues)
- Easy to cache, debug, and document
- No need for GraphQL complexity

**API Conventions:**
- Base URL: `https://api.{pod-domain}/v1/`
- Authentication: Bearer token (JWT)
- Content-Type: `application/json`
- Versioning: URL path (`/v1/`, `/v2/`)

**Example Endpoints:**
```
POST   /v1/auth/register          # Register with phone + OTP
POST   /v1/auth/verify-otp        # Verify OTP
POST   /v1/auth/login             # Biometric/PIN login
POST   /v1/auth/refresh           # Refresh JWT token

GET    /v1/issues                 # List issues (with filters)
POST   /v1/issues                 # Report new issue
GET    /v1/issues/{id}            # Get issue details
PATCH  /v1/issues/{id}/state      # Update issue state
POST   /v1/issues/{id}/photos     # Add photo to issue

GET    /v1/sectors                # List sectors
GET    /v1/sectors/{id}/issues    # Issues in sector

GET    /v1/members/me             # Current user profile
GET    /v1/members/me/issues      # My reported issues

GET    /v1/reports/heat           # Heat report (admin)
GET    /v1/reports/summary        # Status summary (admin)
```

**Documentation:** Auto-generated via SpringDoc OpenAPI (Swagger UI)

---

## 10. Authentication & Security

### Member Authentication (Mobile App)

| Step | Method | Details |
|------|--------|---------|
| Registration | Phone + OTP | SMS via Twilio or Africa's Talking |
| PIN setup | 4-digit PIN | Stored as bcrypt hash |
| Biometric | Fingerprint/Face | Device-level, unlocks local credentials |
| Daily login | Biometric or PIN | Returns JWT token |
| Session duration | 90 days | Then requires OTP re-verification |
| New device | OTP required | Prevents unauthorized access |

### Admin Authentication (Web App)

| Step | Method | Details |
|------|--------|---------|
| Login | Email + Password | Standard form |
| Password storage | bcrypt | Salted hash |
| Session | JWT | Shorter expiry than mobile (e.g., 7 days) |
| Future | 2FA (TOTP) | For Pod/Sector Chiefs |

### JWT Token Structure
```json
{
  "sub": "user_id",
  "pod": "pod_id",
  "sector": "sector_id",
  "roles": ["MEMBER", "COMMUNITY_ADMIN"],
  "exp": 1234567890
}
```

### Security Measures
- All traffic over HTTPS
- Rate limiting on auth endpoints
- Account lockout after failed attempts
- Audit logging for admin actions
- CORS configured per pod domain

---

## 11. SMS Provider Options

For OTP delivery in South Africa:

| Provider | Pros | Cons | Approx Cost |
|----------|------|------|-------------|
| **Africa's Talking** | Local, good SA coverage, easy API | Smaller globally | ~R0.22/SMS |
| **Twilio** | Industry standard, reliable | More expensive | ~R0.35/SMS |
| **Clickatell** | SA-based, enterprise focus | Complex pricing | Varies |

**Recommendation:** Africa's Talking for cost-effectiveness in SA market.

---

## 12. Development Tools

| Purpose | Tool |
|---------|------|
| Version Control | Git + GitHub |
| Mobile IDE | Android Studio / VS Code with Flutter |
| Backend IDE | IntelliJ IDEA |
| Web IDE | VS Code |
| API Testing | Postman or Insomnia |
| Database Client | DBeaver or pgAdmin |
| CI/CD | GitHub Actions |
| Containerization | Docker |

---

## 13. Future Considerations

### Offline Support (Phase 2+)
- Flutter has good offline-first libraries (Hive, Drift)
- Backend would need sync conflict resolution
- Design API to support eventual consistency

### AI Integration (Phase 2+)
- Photo classification: TensorFlow Lite on device or cloud API
- Duplicate detection: Image similarity via ML
- Python microservice alongside Kotlin backend, or external API

### Scaling to AWS/Azure (If Needed)
- Containerized backend (Docker) makes migration easy
- PostgreSQL is available managed on all clouds
- R2 is S3-compatible, can switch to S3 if needed

---

## 14. Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | December 2025 | Initial technology selections |

---

## Next Steps

1. **Entity-Relationship Model** - Database schema design
2. **User Stories** - MVP feature set with acceptance criteria
3. **Project Setup** - Initialize repositories, CI/CD, development environments
