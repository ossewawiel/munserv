# MunServ Mock API

Mock API server for MVP development. Simulates all backend endpoints so mobile and web apps can be developed in parallel.

## Quick Start

```bash
# Install dependencies
npm install

# Start server
npm start

# Or with auto-restart on changes
npm run dev
```

Server runs at `http://localhost:3001`

## Test Credentials

### Mobile App (Member)
- **Phone:** `+27821234567`
- **OTP:** `123456` (always this for testing)
- **PIN:** `1234`

### Web Admin
- **Email:** `admin@ward42.example.com`
- **Password:** `admin123`

## API Endpoints

See [`specs/MVP_Development_Guide.md`](../../specs/MVP_Development_Guide.md) for complete API documentation.

### Quick Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Request OTP |
| POST | `/api/v1/auth/verify-otp` | Verify OTP |
| POST | `/api/v1/auth/complete-registration` | Complete registration |
| POST | `/api/v1/auth/login` | Login with PIN |
| POST | `/api/v1/auth/admin/login` | Admin login |
| GET | `/api/v1/issues` | List issues |
| GET | `/api/v1/issues/:id` | Get issue details |
| POST | `/api/v1/issues` | Create issue |
| PATCH | `/api/v1/issues/:id/state` | Update issue state |
| GET | `/api/v1/issues/mine` | My reported issues |
| GET | `/api/v1/sectors` | List sectors |
| GET | `/api/v1/admin/dashboard` | Dashboard stats |
| GET | `/api/v1/admin/reports/heat` | Heat report |
| GET | `/api/v1/admin/members` | Members list |

## Mock Data

Data files in `./data/`:
- `sectors.json` - Test sectors
- `members.json` - Test members
- `issues.json` - Test issues
- `admins.json` - Test admin users

Edit these files to add more test data. Changes require server restart.

## File Uploads

Photos uploaded via `/api/v1/issues` are stored in `./uploads/` and served at `http://localhost:3001/uploads/{filename}`.

## Notes

- OTP is always `123456` for any phone number
- Tokens are mock JWTs (not cryptographically valid)
- Data resets when server restarts
- All dates are ISO 8601 format
