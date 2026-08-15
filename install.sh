#!/usr/bin/env bash
# Installer for hamberger-dl.
# Usage: curl -fsSL https://raw.githubusercontent.com/faramirezs/hamberger-dl/main/install.sh | bash
set -euo pipefail

VERSION="${1:-main}"
URL="https://raw.githubusercontent.com/faramirezs/hamberger-dl/$VERSION/hamberger-dl"
DEST_DIR="${HAMBERGER_INSTALL_DIR:-$HOME/bin}"

command -v curl >/dev/null || { echo "error: curl is required"; exit 1; }

mkdir -p "$DEST_DIR"
curl -fsSL "$URL" -o "$DEST_DIR/hamberger-dl"
chmod +x "$DEST_DIR/hamberger-dl"

echo "Installed hamberger-dl -> $DEST_DIR/hamberger-dl"

case ":$PATH:" in
  *":$DEST_DIR:"*) ;;
  *)
    echo
    echo "Note: $DEST_DIR is not on your PATH. Add it, e.g.:"
    echo "  echo 'export PATH=\"$DEST_DIR:\$PATH\"' >> ~/.zshrc"
    echo "  source ~/.zshrc"
    ;;
esac

echo
echo "Next: run 'hamberger-dl login' (once), then 'hamberger-dl download'."
