# MunServ

Community-powered municipal issue tracking. Report potholes, water leaks, broken streetlights, and more — right from your phone.

## What is this?

MunServ helps communities track and report infrastructure problems to local authorities. Community members snap photos of issues, and administrators manage them through a web dashboard.

**How it works:**
1. Member sees a pothole → takes photo → reports via mobile app
2. Issue appears on map with GPS location
3. Admin reviews, confirms, and tracks progress
4. Community can see status updates

## Project Structure

```
munserv/
├── mobile/          # Flutter app (iOS & Android)
├── web/             # React admin dashboard
├── backend/         # Kotlin + Spring Boot API (coming soon)
├── infrastructure/  # Docker, mock API, deployment configs
├── specs/           # Technical specifications
└── database/        # Migrations and seeds (coming soon)
```

## Quick Start

### Prerequisites

- Node.js 18+
- Flutter 3.x
- pnpm (for web)

### 1. Start the Mock API

```bash
cd infrastructure/mock-api
npm install
npm start
# Runs on http://localhost:3001
```

### 2. Run the Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

### 3. Run the Web Admin

```bash
cd web
pnpm install
pnpm dev
# Runs on http://localhost:3000
```

## MVP Features

### Mobile App (Members)
- Phone + OTP registration
- Report issues with photos and GPS
- View issues on map
- Track your reported issues

### Web Dashboard (Admins)
- Email/password login
- Dashboard with stats
- Manage issue states
- View heat report (priority ranking)

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter, Riverpod, Freezed |
| Web | React, TypeScript, React Query, Vite |
| Backend | Kotlin, Spring Boot (Phase 2) |
| Database | PostgreSQL + PostGIS (Phase 2) |
| Storage | Cloudflare R2 (Phase 2) |

## Issue Types

- Potholes / road damage
- Water pipe leaks
- Sewage leaks
- Broken traffic lights
- Broken street lights
- Illegal dumping

## Architecture

Each deployment is a **pod** — an independent instance with its own database and infrastructure. A pod serves one or more communities (wards, towns, regions).

```
┌─────────────────────────────────────────┐
│                  Pod                     │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │ Sector  │  │ Sector  │  │ Sector  │  │
│  │ Ward 42 │  │ Ward 43 │  │ Ward 44 │  │
│  └─────────┘  └─────────┘  └─────────┘  │
└─────────────────────────────────────────┘
```

## Documentation

| Document | Description |
|----------|-------------|
| [MVP Development Guide](specs/MVP_Development_Guide.md) | Start here — scope, API contract, mock data |
| [Architecture & Patterns](specs/Architecture_and_Design_Patterns.md) | Code structure and conventions |
| [Domain & Data Modeling](specs/Domain_and_Data_Modeling.md) | Entities, workflows, state machines |
| [Coding Standards](specs/Coding_Standards.md) | Style guides for all platforms |

## Contributing

This is an open source project. Communities should only pay for hosting costs — no licensing fees.

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/awesome`)
3. Commit your changes
4. Push and open a PR

## License

MIT

---

*Built for communities, by communities.*
