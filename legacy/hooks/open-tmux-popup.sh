#!/bin/bash
# Delayed tmux popup launcher for breathing exercises
# Called by on-start.sh, runs in background

MARKER_FILE="/tmp/mindful-claude-working"
LOCKFILE="/tmp/mindful-tmux-popup.lock"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREATHE_SCRIPT="$SCRIPT_DIR/breathe.sh"

# Read config (env vars override config file, config file overrides defaults)
CONFIG_FILE="$HOME/.claude/mindful/config"
config_delay=""
if [ -f "$CONFIG_FILE" ]; then
    config_delay=$(grep "^delay=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
fi

# Options: "pane" (default, non-blocking), "popup" (blocking), "off"
MINDFUL_TMUX_UI="${MINDFUL_TMUX_UI:-pane}"
MINDFUL_DELAY_SECONDS="${MINDFUL_DELAY_SECONDS:-${config_delay:-5}}"
PANE_ID_FILE="/tmp/mindful-tmux-pane-id"

# Exit if UI mode is off
if [ "$MINDFUL_TMUX_UI" = "off" ]; then
    exit 0
fi

# Exit if not in tmux
if [ -z "$TMUX" ]; then
    exit 0
fi

# Check if tmux supports display-popup (version >= 3.2)
if ! tmux display-popup -h 2>&1 | grep -q "usage"; then
    # Older versions don't have display-popup
    tmux_version=$(tmux -V | sed 's/tmux //' | cut -d. -f1,2)
    if ! awk "BEGIN {exit !($tmux_version >= 3.2)}"; then
        exit 0
    fi
fi

# Capture the current client immediately (before sleeping)
client=$(tmux display-message -p '#{client_tty}')

# Wait for the configured delay
sleep "$MINDFUL_DELAY_SECONDS"

# Re-check if Claude is still working
if [ ! -f "$MARKER_FILE" ]; then
    exit 0
fi

# Try to acquire lock (prevent duplicate popups)
if ! mkdir "$LOCKFILE" 2>/dev/null; then
    # Another popup is already running
    exit 0
fi

# Cleanup lock on exit
cleanup() {
    rmdir "$LOCKFILE" 2>/dev/null
}
trap cleanup EXIT

# Open UI based on mode
if [ "$MINDFUL_TMUX_UI" = "pane" ]; then
    # Split a small pane at bottom, don't focus it (-d)
    # -l 12: 12 lines tall
    # -d: don't switch focus
    # -P: print pane info
    pane_id=$(tmux split-window -d -v -l 12 -P -F '#{pane_id}' "$BREATHE_SCRIPT")
    echo "$pane_id" > "$PANE_ID_FILE"
else
    # Original popup mode
    # -E: close popup on script exit
    # -w 30 -h 15: popup dimensions
    # -T: title with emoji
    tmux display-popup -E -w 30 -h 15 -T "🧘 Breathe" "$BREATHE_SCRIPT"
fi
