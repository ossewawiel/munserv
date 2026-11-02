#!/usr/bin/env bash
# Installs the factory tick as a systemd user timer (no sudo) and enables it.
#
# Copies infrastructure/systemd/tick.env.example to ~/.config/munserv-factory/tick.env when that
# file does not exist yet, then writes the two units from their templates. Rerun it after changing
# the hours in tick.env, after the checkout moves, or after the toolchain PATH changes.
#
# Usage: scripts/install-factory-tick.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${MUNSERV_FACTORY_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/munserv-factory}"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
TEMPLATES="$DIR/infrastructure/systemd"

mkdir -p "$CONFIG_DIR" "$UNIT_DIR"
if [[ ! -f "$CONFIG_DIR/tick.env" ]]; then
  cp "$TEMPLATES/tick.env.example" "$CONFIG_DIR/tick.env"
  echo "Wrote $CONFIG_DIR/tick.env from the template."
fi

# shellcheck source=/dev/null
source "$CONFIG_DIR/tick.env"
FIRST="${TICK_FIRST_HOUR:-7}"
LAST="${TICK_LAST_HOUR:-21}"
EVERY="${TICK_EVERY_HOURS:-2}"
ON_CALENDAR="$(printf '*-*-* %02d..%02d/%d:00:00' "$FIRST" "$LAST" "$EVERY")"
systemd-analyze calendar "$ON_CALENDAR" >/dev/null

# '|' cannot occur in either value's role here; a path containing it would be unusual enough to fail loudly.
sed -e "s|@REPO@|$DIR|g" -e "s|@PATH@|$PATH|g" "$TEMPLATES/munserv-factory.service" >"$UNIT_DIR/munserv-factory.service"
sed -e "s|@ON_CALENDAR@|$ON_CALENDAR|g" "$TEMPLATES/munserv-factory.timer" >"$UNIT_DIR/munserv-factory.timer"

systemctl --user daemon-reload
systemctl --user enable --now munserv-factory.timer

echo "Installed munserv-factory.{service,timer} (runs $DIR/scripts/factory-tick.sh, $ON_CALENDAR)."
echo "Next tick: systemctl --user list-timers munserv-factory.timer"
echo "Logs:      journalctl --user -u munserv-factory -f"
echo "To keep it running after you log out, run once:  loginctl enable-linger $USER"
