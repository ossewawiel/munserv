# MunServ Web Admin Portal

React + TypeScript + MUI admin portal for managing municipal issues.

## Getting Started

1. **Start the backend:**
   ```bash
   cd ../backend
   ./gradlew bootRun
   ```
   Backend runs on http://localhost:8080

2. **Start the web app:**
   ```bash
   pnpm install
   pnpm dev
   ```
   Web app runs on http://localhost:3000

3. **Login:**
   - Email: `admin@ward42.example.com`
   - Password: `admin123`

## Development Commands

```bash
pnpm dev          # Start dev server
pnpm build        # Production build
pnpm lint         # ESLint check
pnpm typecheck    # TypeScript check
```

## Tech Stack

- **React 18** with TypeScript
- **MUI v7** for components and theming
- **React Query** for server state
- **React Router** for navigation
- **Axios** for HTTP client

## Project Structure

See `CLAUDE.md` for detailed architecture and coding patterns.
