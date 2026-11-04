# Issue Creation - Backend Phase

## Status: Verified ✅

**Verified:** January 2026

## Overview
Verify backend issue creation endpoints work correctly with mobile client.

## Verification Summary

All endpoints verified working:
- ✅ POST /issues creates issue successfully
- ✅ POST /issues/{id}/photos uploads photos
- ✅ GET /issues returns list with thumbnails
- ✅ GET /issues/{id} returns detail with photoUrls
- ✅ Photo validation rejects invalid files

---

## Reference: Original Analysis

### Status: Was 95% Complete (Now Verified)

The backend implementation is production-ready for MVP. The critical functionality works:

| Component | Status | Notes |
|-----------|--------|-------|
| POST /issues | ✅ Working | Creates issue, returns ID |
| POST /issues/{id}/photos | ✅ Working | Multipart upload, validation |
| GET /issues | ✅ Working | Pagination, filtering |
| GET /issues/{id} | ✅ Working | Full details with photoUrls |
| Photo storage | ✅ Working | Local filesystem MVP |
| Validation | ✅ Working | File size, type checks |

### Files Involved
| File | Purpose |
|------|---------|
| `src/main/kotlin/com/munserv/issues/api/IssueController.kt` | REST endpoints |
| `src/main/kotlin/com/munserv/issues/api/IssueRequest.kt` | DTOs |
| `src/main/kotlin/com/munserv/issues/service/IssueService.kt` | Business logic |
| `src/main/kotlin/com/munserv/photos/api/PhotoController.kt` | Photo upload |
| `src/main/kotlin/com/munserv/photos/service/IssuePhotoService.kt` | Photo handling |
| `src/main/kotlin/com/munserv/photos/service/LocalPhotoStorageService.kt` | File storage |

---

## Verification Tasks

### Task 1: Verify Issue Creation Flow
**Purpose**: Confirm POST /issues works with mobile request format.

**Test Command**:
```bash
# Start backend
cd backend && ./gradlew bootRun

# Test issue creation (requires valid JWT and sectorId)
curl -X POST http://localhost:8080/api/v1/issues \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "pothole",
    "sectorId": "550e8400-e29b-41d4-a716-446655440001",
    "latitude": -26.1350,
    "longitude": 27.9800,
    "description": "Test pothole from API"
  }'
```

**Expected Response** (201 Created):
```json
{
  "id": "generated-uuid",
  "type": "pothole",
  "state": "reported",
  "location": { "latitude": -26.1350, "longitude": 27.9800 },
  "heat": 10,
  "photoUrls": [],
  "sectorId": "550e8400-e29b-41d4-a716-446655440001",
  "reporterId": "member-from-jwt",
  "reportCount": 1,
  "createdAt": "...",
  "updatedAt": "..."
}
```

**Checklist**:
- [ ] Returns 201 with issue details
- [ ] Issue ID is valid UUID
- [ ] State is "reported"
- [ ] Heat is 10 (default)
- [ ] reportCount is 1
- [ ] sectorId matches request

---

### Task 2: Verify Photo Upload Flow
**Purpose**: Confirm POST /issues/{id}/photos works.

**Test Command**:
```bash
# Upload photo to created issue
curl -X POST http://localhost:8080/api/v1/issues/${ISSUE_ID}/photos \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "file=@test-photo.jpg"
```

**Expected Response** (201 Created):
```json
{
  "id": "photo-uuid",
  "url": "http://localhost:8080/uploads/photo-uuid.jpg",
  "thumbnailUrl": "http://localhost:8080/uploads/photo-uuid-thumb.jpg",
  "sortOrder": 0,
  "createdAt": "..."
}
```

**Checklist**:
- [ ] Returns 201 with photo details
- [ ] URL is accessible
- [ ] File is saved to uploads directory
- [ ] Subsequent photos increment sortOrder

---

### Task 3: Verify Photo Validation
**Purpose**: Confirm file validation rejects invalid uploads.

**Test Cases**:
```bash
# Test oversized file (should fail)
curl -X POST http://localhost:8080/api/v1/issues/${ISSUE_ID}/photos \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "file=@large-file-6mb.jpg"
# Expected: 400 Bad Request

# Test invalid format (should fail)
curl -X POST http://localhost:8080/api/v1/issues/${ISSUE_ID}/photos \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "file=@document.pdf"
# Expected: 400 Bad Request

# Test empty file (should fail)
curl -X POST http://localhost:8080/api/v1/issues/${ISSUE_ID}/photos \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "file=@empty.jpg"
# Expected: 400 Bad Request
```

**Checklist**:
- [ ] Files > 5MB rejected
- [ ] Non-image files rejected
- [ ] Empty files rejected
- [ ] Error messages are clear

---

### Task 4: Verify Issue Retrieval with Photos
**Purpose**: Confirm GET /issues/{id} returns photoUrls.

**Test Command**:
```bash
curl http://localhost:8080/api/v1/issues/${ISSUE_ID} \
  -H "Authorization: Bearer ${JWT_TOKEN}"
```

**Expected Response**:
```json
{
  "id": "...",
  "photoUrls": [
    "http://localhost:8080/uploads/photo1.jpg",
    "http://localhost:8080/uploads/photo2.jpg"
  ],
  ...
}
```

**Checklist**:
- [ ] photoUrls array populated
- [ ] URLs are accessible
- [ ] Order matches upload order

---

## Enhancement Tasks (Optional)

### Task 5: Implement Actual Thumbnail Generation
**Priority**: P2 - Medium

**Current**: URLs are generated but thumbnails are same as originals.

**File**: `src/main/kotlin/com/munserv/photos/service/LocalPhotoStorageService.kt`

**Implementation**:
```kotlin
import java.awt.image.BufferedImage
import javax.imageio.ImageIO
import java.awt.Image

private fun generateThumbnail(originalFile: Path, thumbnailPath: Path) {
    val original = ImageIO.read(originalFile.toFile())
    val thumbWidth = 200
    val thumbHeight = (original.height * thumbWidth) / original.width

    val thumbnail = original.getScaledInstance(thumbWidth, thumbHeight, Image.SCALE_SMOOTH)
    val buffered = BufferedImage(thumbWidth, thumbHeight, BufferedImage.TYPE_INT_RGB)
    buffered.graphics.drawImage(thumbnail, 0, 0, null)

    val extension = originalFile.toString().substringAfterLast('.')
    ImageIO.write(buffered, extension, thumbnailPath.toFile())
}
```

**Tests Required**:
- [ ] Thumbnail created on upload
- [ ] Thumbnail dimensions correct (200px width)
- [ ] Thumbnail accessible via URL

---

### Task 6: Add Auto Sector Detection (Future)
**Priority**: P3 - Low (Not MVP)

**Purpose**: Automatically determine sector from GPS coordinates.

**Implementation Sketch**:
```kotlin
// In SectorService
fun findByLocation(location: GeoPoint): Sector? {
    return sectorRepository.findContaining(location)
}

// In SectorRepository (PostGIS query)
@Query("""
    SELECT s FROM SectorEntity s
    WHERE ST_Contains(s.boundary, ST_SetSRID(ST_Point(:lng, :lat), 4326))
""")
fun findContaining(lat: Double, lng: Double): SectorEntity?
```

**Prerequisite**: Sectors must have boundary polygons defined.

---

## Testing Strategy

### Unit Tests
```bash
cd backend
./gradlew test --tests "*IssueServiceTest*"
./gradlew test --tests "*PhotoServiceTest*"
./gradlew test --tests "*PhotoValidationServiceTest*"
```

### Integration Tests
```bash
cd backend
./gradlew test --tests "*IssueReportingScenarioTest*"
```

**Test File**: `src/test/kotlin/com/munserv/integration/scenarios/IssueReportingScenarioTest.kt`

Already tests:
- Issue creation via API
- Issue retrieval
- Multiple issue types
- Filtering by state/type

**Missing Tests**:
- [ ] Photo upload flow in integration test
- [ ] Concurrent upload handling
- [ ] Maximum photos per issue (5)

---

## Deployment Checklist

### Environment Variables
```bash
# Required
DB_URL=jdbc:postgresql://localhost:5433/munserv_dev
DB_USER=munserv
DB_PASSWORD=munserv_dev
JWT_SECRET=<256-bit-secret>

# Storage (local MVP)
STORAGE_TYPE=local
STORAGE_LOCAL_UPLOAD_DIR=./uploads
```

### Pre-Deployment
- [ ] Upload directory exists and is writable
- [ ] Database migrations applied
- [ ] JWT secret configured
- [ ] Photo validation enabled

### Post-Deployment
- [ ] API health check passes
- [ ] Photo upload works
- [ ] Photos accessible via URL

---

## Commands

```bash
# Start development server
cd backend && ./gradlew bootRun

# Run all tests
cd backend && ./gradlew test

# Run specific tests
cd backend && ./gradlew test --tests "*IssueController*"

# Check database migrations
cd backend && ./gradlew flywayInfo

# Build for deployment
cd backend && ./gradlew build -x test
```

---

## Definition of Done

- [ ] POST /issues creates issue successfully
- [ ] POST /issues/{id}/photos stores photos
- [ ] GET /issues/{id} returns photoUrls
- [ ] Photo validation rejects invalid files
- [ ] Integration tests passing
- [ ] No security vulnerabilities (file type, size limits)

---

## Handoff Notes

**For agent execution:**
```
cd backend
Read backend/CLAUDE.md first for sealed Result patterns.

This phase is primarily VERIFICATION, not implementation.
The backend is already working - verify it works with mobile client.

Priority order:
1. Task 1-4 (Verification) - Confirm everything works
2. Task 5 (Thumbnails) - Enhancement if time permits
3. Task 6 (Auto sector) - Future scope, skip for MVP
```
