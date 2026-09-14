#!/bin/bash
# Hook: Called when Claude stops working

MARKER_FILE="/tmp/mindful-claude-working"
PANE_ID_FILE="/tmp/mindful-tmux-pane-id"

# Remove marker file (triggers popup auto-close)
rm -f "$MARKER_FILE"

# Kill the breathing pane if it exists
if [ -f "$PANE_ID_FILE" ]; then
    pane_id=$(cat "$PANE_ID_FILE")
    tmux kill-pane -t "$pane_id" 2>/dev/null
    rm -f "$PANE_ID_FILE"
fi
