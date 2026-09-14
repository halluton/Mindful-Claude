#!/bin/bash
# Set the breathing exercise for the mindful pane
# Usage: set-exercise.sh [hrv|sigh|box|hyper]

CONFIG_DIR="$HOME/.claude/mindful"
CONFIG_FILE="$CONFIG_DIR/config"

# Ensure config exists
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_FILE" ]; then
    printf 'enabled=true\nexercise=0\ndelay=5\n' > "$CONFIG_FILE"
fi

set_exercise() {
    if grep -q "^exercise=" "$CONFIG_FILE"; then
        tmp=$(mktemp)
        sed "s/^exercise=.*/exercise=$1/" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
    else
        echo "exercise=$1" >> "$CONFIG_FILE"
    fi
}

case "${1,,}" in
    hrv|coherence|0)
        set_exercise 0
        echo "Set to Coherent Breathing (5.5s in, 5.5s out)"
        ;;
    sigh|physiological|1)
        set_exercise 1
        echo "Set to Physiological Sigh (double inhale + long exhale)"
        ;;
    box|boxing|2)
        set_exercise 2
        echo "Set to Box Breathing (4s in, 4s hold, 4s out, 4s hold)"
        ;;
    478|relax|3)
        set_exercise 3
        echo "Set to 4-7-8 Breathing (4s in, 7s hold, 8s out)"
        ;;
    list|"")
        echo "Available exercises:"
        echo "  hrv   - Coherent Breathing (5.5s in, 5.5s out)"
        echo "  sigh  - Physiological Sigh (double inhale + long exhale)"
        echo "  box   - Box Breathing (4s in, 4s hold, 4s out, 4s hold)"
        echo "  478   - 4-7-8 Breathing (4s in, 7s hold, 8s out)"
        current=0
        if [ -f "$CONFIG_FILE" ]; then
            current=$(grep "^exercise=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
        fi
        echo ""
        echo "Current: ${current:-0}"
        ;;
    *)
        echo "Unknown exercise: $1"
        echo "Run without arguments to see options"
        exit 1
        ;;
esac
