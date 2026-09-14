#!/bin/bash
# Hook: Called when Claude starts working

MARKER_FILE="/tmp/mindful-claude-working"
PANE_ID_FILE="/tmp/mindful-tmux-pane-id"
LOCKFILE="/tmp/mindful-tmux-popup.lock"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.claude/mindful/config"

# Exit early if disabled
if [ -f "$CONFIG_FILE" ] && grep -q "^enabled=false" "$CONFIG_FILE"; then
    exit 0
fi

# Clean up any leftover pane from a previous run (e.g. if Stop hook didn't fire)
if [ -f "$PANE_ID_FILE" ]; then
    old_pane=$(cat "$PANE_ID_FILE")
    tmux kill-pane -t "$old_pane" 2>/dev/null
    rm -f "$PANE_ID_FILE"
fi
rmdir "$LOCKFILE" 2>/dev/null

# Create marker file with timestamp
echo "$(date +%s)" > "$MARKER_FILE"

# Launch tmux popup in background (if in tmux)
if [ -n "$TMUX" ]; then
    "$SCRIPT_DIR/open-tmux-popup.sh" &
fi
