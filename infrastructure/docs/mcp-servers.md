# MCP servers

Servers live in `.mcp.json`; plugins in `enabledPlugins` of `.claude/settings.json`. Web fetch is the built-in `WebFetch` and GitHub goes through `gh`, so neither has a server. `context7` is set to `false` in `enabledPlugins` (it fails OAuth `invalid_target`). Export `MUNSERV_DB_URL` (for the dev database: `postgresql://munserv:munserv_dev@localhost:5435/munserv_dev`) before you start Claude Code.

| Name | Kind | Runs | Used by | Notes |
|---|---|---|---|---|
| `postgres` | MCP server | `docker run` of `crystaldba/postgres-mcp:0.3.0`, `--access-mode=restricted`, `--init`, `--network host`, URL from `MUNSERV_DB_URL` | `investigator` (`execute_sql`, `list_objects`, `get_object_details`) | Read-only; the restricted parser rejects writes and some functions such as `postgis_full_version()`. Check PostGIS with `pg_extension`. The container takes about 19 s to answer, so `MCP_TIMEOUT=60000` in `.claude/settings.json` lifts the 30 s default; without it the server shows "timed out". `--init` lets SIGTERM stop the container, so none outlive the session. The PyPI package does not install (`pglast==7.2.0` is missing), so use the image. |
| `playwright` | MCP server | `npx -y @playwright/mcp` | web UI checks in a session | Not granted to any agent. |
| `typescript-lsp` | plugin (`claude-plugins-official`) | `typescript-language-server` on PATH | `web-implementer` (`LSP` tool) | Install once: `npm install -g typescript-language-server typescript`. |
| `dart-flutter` | plugin (marketplace `flutter/agent-plugins`) | `dart mcp-server` from the Dart SDK on PATH, plus 25 Dart and Flutter skills | `mobile-implementer` (all `dart-mcp-server` tools) | Official Dart and Flutter team plugin, v1.0.7. Adds about 2.5k tokens to every session. |

