# Feature: Issue Creation Flow

## Summary
Enable members to report infrastructure issues via mobile app with photos and GPS location, with proper backend storage and web admin visibility.

## Status: Complete ✅

**Completed:** January 2026

### Implementation Summary
| Platform | Status | Notes |
|----------|--------|-------|
| Mobile | ✅ Complete | Multi-step wizard, GPS, photo upload |
| Backend | ✅ Complete | CRUD API, photo storage, validation |
| Web | ✅ Complete | List view, detail view, photo gallery |

### What Was Fixed
1. ~~Mobile: Hardcoded GPS location~~ → Real GPS via LocationService
2. ~~Mobile: Missing sectorId~~ → Read from member profile
3. ~~Mobile: No image validation~~ → Size/format checks added

### Known Limitations (Future Enhancements)
- Backend: Thumbnails are same as originals (no resize)
- Web: Manual refresh required for new issues
- Mobile: Map preview uses placeholder icon

## User Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ISSUE CREATION FLOW                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. SELECT PHOTOS (1-5)                                             │
│     ├── Camera capture                                              │
│     └── Gallery selection                                           │
│           ↓                                                         │
│  2. SELECT ISSUE TYPE                                               │
│     └── pothole | water_leak | sewage_leak | traffic_light |       │
│         street_light | illegal_dumping | other                      │
│           ↓                                                         │
│  3. CONFIRM LOCATION                                                │
│     ├── Auto-detect from GPS                                        │
│     ├── Extract from photo EXIF (fallback)                          │
│     └── Manual adjustment via map (optional)                        │
│           ↓                                                         │
│  4. ADD DESCRIPTION (optional)                                      │
│     └── Max 1000 characters                                         │
│           ↓                                                         │
│  5. SUBMIT                                                          │
│     ├── POST /issues (JSON) → returns issue ID                      │
│     └── POST /issues/{id}/photos (multipart) × N photos             │
│           ↓                                                         │
│  6. CONFIRMATION                                                    │
│     └── Show success message + issue ID                             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## API Endpoints

| Method | Path | Purpose | Status |
|--------|------|---------|--------|
| POST | /api/v1/issues | Create issue | ✅ Ready |
| POST | /api/v1/issues/{id}/photos | Upload photo | ✅ Ready |
| GET | /api/v1/issues | List issues | ✅ Ready |
| GET | /api/v1/issues/{id} | Issue detail | ✅ Ready |

## Technical Requirements

### Photo Handling
- Max 5 photos per issue
- Compress to max 1920x1920 at 85% quality
- Max file size: 5MB
- Formats: JPEG, PNG, WebP

### Location
- Primary: Device GPS (geolocator)
- Fallback: Photo EXIF data
- Accuracy: Within 100 meters acceptable
- Store as PostGIS Point (SRID 4326)

### Sector Assignment
- Client provides `sectorId` from member profile
- Future: Auto-detect from GPS coordinates

## Definition of Done

- [x] Member can capture/select 1-5 photos
- [x] Photos compressed before upload
- [x] Real GPS location captured (not hardcoded)
- [x] Issue saved with correct sector
- [x] Photos visible in web admin portal
- [x] Confirmation shown to member
- [x] All tests passing

## Related Documents

- [Mobile Phase](./mobile-phase.md)
- [Backend Phase](./backend-phase.md)
- [Web Phase](./web-phase.md)
- [API Contract](../../contracts/api.md)
