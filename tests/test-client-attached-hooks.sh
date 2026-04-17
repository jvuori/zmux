#!/bin/bash
# Regression test: keep all client-attached handlers appended.

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSIONS_CONF="$REPO_ROOT/tmux/sessions.conf"
KEYBINDINGS_CONF="$REPO_ROOT/tmux/keybindings.conf"

echo "Testing client-attached hook append semantics..."
echo "Using sessions file: $SESSIONS_CONF"
echo "Using keybindings file: $KEYBINDINGS_CONF"

# sessions.conf must never replace the hook chain after keybindings append handlers.
if grep -Eq "^set-hook -g client-attached " "$SESSIONS_CONF"; then
	echo "ERROR: sessions.conf contains 'set-hook -g client-attached' which overwrites existing handlers"
	exit 1
fi

if ! grep -Eq "^set-hook[[:space:]]+-ag[[:space:]]+client-attached[[:space:]]+'refresh-client -S'[[:space:]]*$" "$SESSIONS_CONF"; then
	echo "ERROR: sessions.conf must append refresh-client with set-hook -ag"
	grep -nE "client-attached" "$SESSIONS_CONF" || true
	exit 1
fi

if ! grep -Eq "^set-hook[[:space:]]+-ag[[:space:]]+client-attached[[:space:]]+'run-shell -b \"~/.config/tmux/scripts/check-update.sh\"'[[:space:]]*$" "$KEYBINDINGS_CONF"; then
	echo "ERROR: keybindings.conf must append check-update.sh on client-attached"
	grep -nE "client-attached|check-update\\.sh" "$KEYBINDINGS_CONF" || true
	exit 1
fi

if ! grep -Eq "^set-hook[[:space:]]+-ag[[:space:]]+client-attached[[:space:]]+'run-shell -b \"sleep 3 && ~/.config/tmux/scripts/capture-cursor-agent-session.sh\"'[[:space:]]*$" "$SESSIONS_CONF"; then
	echo "ERROR: sessions.conf must append capture-cursor-agent-session.sh on client-attached"
	grep -nE "client-attached|capture-cursor-agent-session\\.sh" "$SESSIONS_CONF" || true
	exit 1
fi

echo "✓ client-attached hooks use append semantics"
exit 0
