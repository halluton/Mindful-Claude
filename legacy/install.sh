#!/bin/bash
# Installer for Mindful Breathing for Claude Code
# Adds hooks to ~/.claude/settings.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
ON_START="$SCRIPT_DIR/hooks/on-start.sh"
ON_STOP="$SCRIPT_DIR/hooks/on-stop.sh"

# Handle --uninstall
if [ "${1}" = "--uninstall" ]; then
    echo "Uninstalling Mindful Breathing hooks..."
    if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
        settings=$(cat "$SETTINGS_FILE")
        settings=$(echo "$settings" | jq \
            --arg on_start "$ON_START" \
            --arg on_stop "$ON_STOP" \
            '(.hooks.UserPromptSubmit // []) |= [.[] | select(.hooks | all(.command != $on_start))] |
             (.hooks.Stop // []) |= [.[] | select(.hooks | all(.command != $on_stop))] |
             if .hooks.UserPromptSubmit == [] then del(.hooks.UserPromptSubmit) else . end |
             if .hooks.Stop == [] then del(.hooks.Stop) else . end |
             if .hooks == {} then del(.hooks) else . end')
        echo "$settings" > "$SETTINGS_FILE"
        echo "Hooks removed from $SETTINGS_FILE"
    else
        echo "Nothing to uninstall."
    fi
    rm -f /tmp/mindful-claude-working /tmp/mindful-tmux-pane-id /tmp/mindful-exercise
    rmdir /tmp/mindful-tmux-popup.lock 2>/dev/null
    rm -rf "$HOME/.claude/mindful"
    rm -f "$HOME/.claude/commands/mindful.md"
    echo "Done."
    exit 0
fi

echo "Mindful Breathing for Claude Code"
echo "================================="
echo ""

# Check prerequisites
if ! command -v tmux &>/dev/null; then
    echo "Warning: tmux not found. The auto-launch feature requires tmux."
    echo "Install it with: brew install tmux (macOS) or apt install tmux (Linux)"
    echo ""
elif tmux show-option -g mouse 2>/dev/null | grep -q "off"; then
    echo "Tip: Enable mouse scrolling in tmux for a better experience:"
    echo "  echo 'set -g mouse on' >> ~/.tmux.conf && tmux source-file ~/.tmux.conf"
    echo ""
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required to install hooks."
    echo "Install it with: brew install jq (macOS) or apt install jq (Linux)"
    exit 1
fi

# Make scripts executable
chmod +x "$SCRIPT_DIR/breathe.sh"
chmod +x "$SCRIPT_DIR/set-exercise.sh"
chmod +x "$SCRIPT_DIR/hooks/on-start.sh"
chmod +x "$SCRIPT_DIR/hooks/on-stop.sh"
chmod +x "$SCRIPT_DIR/hooks/open-tmux-popup.sh"

# Create directories
mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.claude/mindful"
mkdir -p "$HOME/.claude/commands"

# Create default config if it doesn't exist
if [ ! -f "$HOME/.claude/mindful/config" ]; then
    # Migrate exercise preference from old /tmp location
    old_exercise=0
    if [ -f "/tmp/mindful-exercise" ]; then
        old_exercise=$(cat /tmp/mindful-exercise 2>/dev/null)
        [ -z "$old_exercise" ] && old_exercise=0
    fi
    printf 'enabled=true\nexercise=%s\ndelay=5\n' "$old_exercise" > "$HOME/.claude/mindful/config"
    echo "Created config at ~/.claude/mindful/config"
fi

# Install /mindful slash command
cp "$SCRIPT_DIR/commands/mindful.md" "$HOME/.claude/commands/mindful.md"
echo "Installed /mindful slash command"

# Start from existing settings or empty object
if [ -f "$SETTINGS_FILE" ]; then
    settings=$(cat "$SETTINGS_FILE")
else
    settings='{}'
fi

# Check if our hooks are already installed
if echo "$settings" | jq -e ".hooks.UserPromptSubmit[]?.hooks[]? | select(.command == \"$ON_START\")" &>/dev/null; then
    echo "Hooks are already installed."
    echo ""
    echo "In Claude Code, type /mindful to toggle on/off or change settings."
    exit 0
fi

# Build the hook entries
start_hook='[{"hooks": [{"type": "command", "command": "'"$ON_START"'", "async": true}]}]'
stop_hook='[{"hooks": [{"type": "command", "command": "'"$ON_STOP"'", "async": true}]}]'

# Merge hooks into settings (append to existing arrays or create new ones)
settings=$(echo "$settings" | jq \
    --argjson start_hook "$start_hook" \
    --argjson stop_hook "$stop_hook" \
    '.hooks //= {} |
     .hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) + $start_hook |
     .hooks.Stop = (.hooks.Stop // []) + $stop_hook')

# Back up existing settings
if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
    echo "Backed up existing settings to $SETTINGS_FILE.backup"
fi

# Write updated settings
echo "$settings" > "$SETTINGS_FILE"

echo "Hooks installed to $SETTINGS_FILE"
echo ""
echo "Restart Claude Code or start a new session for hooks to take effect."
echo ""
echo "In Claude Code, type /mindful to toggle on/off or change settings."
echo ""
echo "To change the breathing exercise from the terminal:"
echo "  $SCRIPT_DIR/set-exercise.sh hrv    # Coherent Breathing"
echo "  $SCRIPT_DIR/set-exercise.sh sigh   # Physiological Sigh"
echo "  $SCRIPT_DIR/set-exercise.sh box    # Box Breathing"
echo "  $SCRIPT_DIR/set-exercise.sh 478    # 4-7-8 Breathing"
echo ""
echo "To uninstall, run: $SCRIPT_DIR/install.sh --uninstall"
