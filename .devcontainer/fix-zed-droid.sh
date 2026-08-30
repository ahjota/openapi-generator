#!/bin/sh
# Fix: Zed's npx external agent launcher runs `node <bin>` on the droid package,
# but droid's postinstall replaces the JS shim with a native binary, causing
# SyntaxError: Invalid or unexpected token.
#
# Workaround: add .npmrc with ignore-scripts=true so the JS shim stays in place.
# See https://github.com/zed-industries/zed/issues/62716
#
# This script is called by postStartCommand in devcontainer.json so the fix
# survives container rebuilds. It's idempotent and silent on success.

set -eu

REG_DIR="$HOME/.local/share/zed/external_agents/registry/npx/factory-droid"

# Registry directory doesn't exist yet (Zed hasn't installed the agent).
# Nothing to fix; Zed will create it on first agent launch.
if [ ! -d "$REG_DIR" ]; then
  exit 0
fi

# Fix already applied (npmrc present and bin/droid is a JS script, not ELF).
if [ -f "$REG_DIR/.npmrc" ]; then
  BIN="$REG_DIR/node_modules/droid/bin/droid"
  if [ -f "$BIN" ] && ! file "$BIN" | grep -q "ELF\|Mach-O"; then
    exit 0
  fi
fi

# Apply the fix: prevent postinstall, reinstall droid so JS shim stays.
echo "[fix-zed-droid] Applying ignore-scripts workaround..."
echo 'ignore-scripts=true' > "$REG_DIR/.npmrc"
rm -rf "$REG_DIR/node_modules/droid"

# Use system npm (devcontainer has the node feature installed).
cd "$REG_DIR" && npm install --silent 2>&1 || true

# Verify
BIN="$REG_DIR/node_modules/droid/bin/droid"
if [ -f "$BIN" ] && ! file "$BIN" | grep -q "ELF\|Mach-O"; then
  echo "[fix-zed-droid] OK: bin/droid is a JS script"
else
  echo "[fix-zed-droid] WARNING: bin/droid may still be a native binary"
fi
