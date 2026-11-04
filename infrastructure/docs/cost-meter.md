# Cost meter (telemetry profile)

```bash
cd infrastructure/docker
docker compose --profile telemetry up -d otel-collector    # start; `docker compose stop otel-collector` stops it
```
The collector appends Claude Code's OTLP metrics and logs to `infrastructure/telemetry/data/*.jsonl`. The console's Cost section (`scripts/console/cost.py`) reads `metrics.jsonl`: cost and tokens per day, per `agent.name`, per model and per story. A run joins a story with `OTEL_RESOURCE_ATTRIBUTES=story.id=<id>`; a run without it counts under `none`.

Facts verified against real runs (Claude Code 2.1.312):
- **Project settings do not start telemetry.** `.claude/settings.json` carries the `env` block, but Claude Code ignored it at project scope: nothing reached the collector until the same variables were exported in the shell, passed with `--settings <file>`, or set in `~/.claude/settings.json`. Until the block is copied to user settings, export it before the run.
- The protocol must be `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf`: the default is gRPC, and 4318 speaks HTTP.
- `agent.name` reads `custom` for every project-defined agent unless `OTEL_LOG_TOOL_DETAILS=1`. With it, the real names (`clerk`, `Explore`) appear. The flag also writes Bash commands, file paths and tool input to `logs.jsonl`, which is why that file is gitignored and the port is localhost only.
- Metrics export every 60 s by default; set `OTEL_METRIC_EXPORT_INTERVAL=3000` for a short run, or the process may exit first.
- The files hold the account email. Do not commit or share them. Do not truncate them while the collector runs; stop it first.
