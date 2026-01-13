# Environments

## Development

| Service | URL | Port |
|---------|-----|------|
| Backend | http://localhost:8080 | 8080 |
| Web | http://localhost:3000 | 3000 |
| Database | localhost:5432 | 5432 |
| Mock API | http://localhost:3001 | 3001 |

**Backend:**
```bash
cd backend && ./gradlew bootRun
```

**Web:**
```bash
cd web && pnpm dev
```

**Mobile:**
```bash
cd mobile && flutter run
```

## Staging

| Service | URL |
|---------|-----|
| Backend | https://api.staging.munserv.example |
| Web | https://admin.staging.munserv.example |

## Production

| Service | URL |
|---------|-----|
| Backend | https://api.munserv.example |
| Web | https://admin.munserv.example |

## Environment Variables

### Backend
```
DATABASE_URL=jdbc:postgresql://localhost:5432/munserv
JWT_SECRET=your-secret-key
OTP_EXPIRY_MINUTES=5
```

### Web
```
VITE_API_URL=http://localhost:8080/api/v1
```

### Mobile
```
API_BASE_URL=http://10.0.2.2:8080/api/v1  # Android emulator
```
