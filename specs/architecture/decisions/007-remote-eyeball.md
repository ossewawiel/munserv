# ADR-007: Remote eyeball through the factory console

**Date:** 2026-10-28
**Status:** Accepted

## Context
Eyeball needs the services of a PR running on the developer laptop, but the tester is often on another machine on the intranet. The console and the dev services listened on localhost only, and the web client called `localhost:8080`, which a remote browser cannot reach.

## Decision
- The console listens on the LAN (`remote.bind`, default `0.0.0.0`) when `remote.enabled` is true in `scripts/console/project.yaml`; `--local` turns it off. Loopback requests need no token. Every other request, static files and API, needs the access token (cookie, `?token=`, or `X-Console-Token`), else 403. The token lives in a 0600 file under the XDG state dir and is stable across restarts.
- Three ports are exposed: web 3000, backend 8080 (Swagger for backend-only checks) and console 3999. PostgreSQL, Redis and Storybook stay local.
- In remote mode the web dev server binds the LAN and calls the API through a relative URL (`VITE_API_URL=/api/v1`); the Vite proxy forwards it to the backend, so no CORS change is needed. The backend's e-mailed links point at the public web URL.
- `POST /api/eyeball/ensure` (`scripts/eyeball-up.sh <pr>`) checks a PR out, prepares it and restarts a service only when its process exited, the checkout HEAD moved since it started, or it is unhealthy. It prints the links, accounts and the one firewall command.
- The console runs as a systemd user unit (`infrastructure/systemd/munserv-console.service`, installed without sudo).

## Consequences
✅ An agent runs one command after approval; the tester opens the printed links from any machine on the subnet.
✅ Handoffs are unchanged: the console rewrites `localhost` to the public host when it shows them.
⚠️ Dev seed passwords such as `super_user` / `super123` are reachable from the subnet through the proxy. Acceptable only on a trusted intranet.
⚠️ The token protects the console only. Web and backend ports have no token; the firewall rule is the barrier.
⚠️ Never expose these ports beyond the subnet. The firewall rule is scoped to the machine's /24 and must be run once by a person with sudo.
