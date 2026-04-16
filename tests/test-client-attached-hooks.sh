#!/bin/bash
# Regression test: keep all client-attached handlers appended.

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSIONS_CONF="$REPO_ROOT/tmux/sessions.conf"
KEYBINDINGS_CONF="$REPO_ROOT/tmux/keybindings.conf"

echo "Testing client-attached hook append semantics..."

# sessions.conf must never replace the hook chain after keybindings append handlers.
if rg -q "^set-hook -g client-attached " "$SESSIONS_CONF"; then
	echo "ERROR: sessions.conf contains 'set-hook -g client-attached' which overwrites existing handlers"
	exit 1
fi

if ! rg -q "^set-hook -ag client-attached 'refresh-client -S'$" "$SESSIONS_CONF"; then
	echo "ERROR: sessions.conf must append refresh-client with set-hook -ag"
	exit 1
fi

if ! rg -q "^set-hook -ag client-attached 'run-shell -b \"~/.config/tmux/scripts/check-update.sh\"'$" "$KEYBINDINGS_CONF"; then
	echo "ERROR: keybindings.conf must append check-update.sh on client-attached"
	exit 1
fi

if ! rg -q "^set-hook -ag client-attached 'run-shell -b \"sleep 3 && ~/.config/tmux/scripts/capture-cursor-agent-session.sh\"'$" "$SESSIONS_CONF"; then
	echo "ERROR: sessions.conf must append capture-cursor-agent-session.sh on client-attached"
	exit 1
fi

echo "✓ client-attached hooks use append semantics"
exit 0
