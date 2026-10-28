#!/usr/bin/env bash
# Installs the factory console as a systemd user service (no sudo) and starts it.
#
# Run it from the checkout the console should run from -- normally the main repo on master -- once,
# and again after that checkout moves or the toolchain PATH changes.
#
# Usage: scripts/install-console-service.sh
# Env:   CONSOLE_UNIT (default munserv-console)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT="${CONSOLE_UNIT:-munserv-console}"
TEMPLATE="$DIR/infrastructure/systemd/$UNIT.service"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "install-console-service.sh: no unit template at $TEMPLATE" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
# '|' cannot occur in either value's role here; a path containing it would be unusual enough to fail loudly.
sed -e "s|@REPO@|$DIR|g" -e "s|@PATH@|$PATH|g" "$TEMPLATE" >"$TARGET_DIR/$UNIT.service"

systemctl --user daemon-reload
systemctl --user enable --now "$UNIT.service"

echo "Installed $TARGET_DIR/$UNIT.service (runs from $DIR)."
echo "Status:  systemctl --user status $UNIT"
echo "Logs:    journalctl --user -u $UNIT -f   (the first lines print the tokenised console link)"
echo "To keep it running after you log out, run once:  loginctl enable-linger $USER"
