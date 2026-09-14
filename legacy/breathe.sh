#!/bin/bash
# Breathing animation for tmux pane or popup
# Auto-closes when Claude finishes (marker file removed)

MARKER_FILE="/tmp/mindful-claude-working"
CONFIG_FILE="$HOME/.claude/mindful/config"

# Color — Claude orange #f7835d
COLOR_BRIGHT='\033[38;2;247;131;93m'
COLOR_DEEP='\033[38;2;247;131;93m'
DIM='\033[2m'
RESET='\033[0m'

# Exercise definitions: name|inhale|hold1|exhale|hold2
EXERCISES=(
    "Coherent Breathing|5.5|0|5.5|0"
    "Physiological Sigh|4|1|10|0|double_inhale"
    "Box Breathing|4|4|4|4"
    "4-7-8 Breathing|4|7|8|0"
)

# Read saved exercise preference, default to 0
current_exercise=0
if [ -f "$CONFIG_FILE" ]; then
    saved=$(grep "^exercise=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
    if [ "$saved" -ge 0 ] 2>/dev/null && [ "$saved" -lt ${#EXERCISES[@]} ] 2>/dev/null; then
        current_exercise=$saved
    fi
fi

# Parse exercise timing
IFS='|' read -r EX_NAME IN_DUR HOLD1_DUR EX_DUR HOLD2_DUR EX_TYPE <<< "${EXERCISES[$current_exercise]}"
EX_TYPE="${EX_TYPE:-standard}"

# Animation styles — pick one randomly
STYLES=("pulse" "ripples" "dots" "wave")
STYLE="${STYLES[$((RANDOM % ${#STYLES[@]}))]}"

MAX_CYCLES=600
TICK_RATE=10

# Convert seconds (supports decimals like 5.5) to ticks
sec_to_ticks() {
    local s=$1
    if [[ "$s" == *.* ]]; then
        local whole=${s%%.*}
        local frac=${s#*.}
        frac=${frac:0:1}
        echo $(( whole * TICK_RATE + frac ))
    else
        echo $(( s * TICK_RATE ))
    fi
}

IN_TICKS=$(sec_to_ticks "$IN_DUR")
H1_TICKS=$(sec_to_ticks "$HOLD1_DUR")
EX_TICKS=$(sec_to_ticks "$EX_DUR")
H2_TICKS=$(sec_to_ticks "$HOLD2_DUR")
CYCLE_TICKS=$((IN_TICKS + H1_TICKS + EX_TICKS + H2_TICKS))

# === Pre-build character arrays ===

# Block fills: BSTR[n] = n × "█"
declare -a BSTR
BSTR[0]=""
for ((i=1; i<=64; i++)); do
    BSTR[$i]="${BSTR[$((i-1))]}█"
done

# Gradient bar halves for pulse: ░▒▓███...███▓▒░
declare -a GBAR_L GBAR_R
GBAR_L[0]=""; GBAR_R[0]=""
for ((i=1; i<=32; i++)); do
    fill=$((i - 3)); [ "$fill" -lt 0 ] && fill=0
    l=""; r=""
    [ "$i" -ge 3 ] && l+="░"
    [ "$i" -ge 2 ] && l+="▒"
    l+="▓${BSTR[$fill]}"
    r+="${BSTR[$fill]}▓"
    [ "$i" -ge 2 ] && r+="▒"
    [ "$i" -ge 3 ] && r+="░"
    GBAR_L[$i]="$l"
    GBAR_R[$i]="$r"
done

# Line strings for ripples
declare -a LSTR_H LSTR_M LSTR_L LSTR_D
LSTR_H[0]=""; LSTR_M[0]=""; LSTR_L[0]=""; LSTR_D[0]=""
for ((i=1; i<=64; i++)); do
    LSTR_H[$i]="${LSTR_H[$((i-1))]}━"
    LSTR_M[$i]="${LSTR_M[$((i-1))]}─"
    LSTR_L[$i]="${LSTR_L[$((i-1))]}╌"
    LSTR_D[$i]="${LSTR_D[$((i-1))]}┈"
done

# Height blocks for wave
HBLK=(" " "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# Dot positions: "row:col_factor" (-1000 to 1000 from center)
DOTS=(
    "3:0" "3:70" "3:-80"
    "2:150" "4:-160" "2:-220" "4:230" "3:300" "3:-310"
    "1:250" "5:-260" "1:-400" "5:410" "2:450" "4:-460"
    "2:-530" "4:540" "3:600" "3:-620"
    "0:400" "6:-420" "0:-600" "6:620" "1:700" "5:-710"
    "1:-800" "5:810" "2:850" "4:-860"
    "0:900" "6:-910" "0:-950" "6:960"
)

# Ease-out (quadratic): fast start, gentle deceleration
ease() {
    local x=$1  # 0-1000
    echo $(( x * (2000 - x) / 1000 ))
}

# Detect pane dimensions
detect_size() {
    local w=""
    if [ -n "$TMUX_PANE" ]; then
        w=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_width}' 2>/dev/null)
    fi
    if [ -z "$w" ] || [ "$w" = "0" ]; then w=$(tput cols 2>/dev/null); fi
    if [ -z "$w" ] || [ "$w" = "0" ]; then w=$(stty size 2>/dev/null | cut -d' ' -f2); fi
    if [ -z "$w" ] || [ "$w" = "0" ]; then w=${COLUMNS:-80}; fi
    PANE_W=$w
    BOX_W=$((PANE_W - 4))
    [ "$BOX_W" -gt 60 ] && BOX_W=60
}
detect_size

# Setup
cleanup() { printf '\033[?25h'; }
trap cleanup EXIT
printf '\033[?25l'

tick=0

while true; do
    [ ! -f "$MARKER_FILE" ] && exit 0

    cycle_tick=$((tick % CYCLE_TICKS))
    cycle=$((tick / CYCLE_TICKS + 1))
    [ "$cycle" -gt "$MAX_CYCLES" ] && exit 0

    t=$cycle_tick
    if [ "$t" -lt "$IN_TICKS" ]; then
        phase="Breathe in"
        remaining_ticks=$((IN_TICKS - t))
        linear=$(( t * 1000 / IN_TICKS ))
        if [ "$EX_TYPE" = "double_inhale" ]; then
            progress=$(( $(ease "$linear") * 850 / 1000 ))
        else
            progress=$(ease "$linear")
        fi
        color="$COLOR_BRIGHT"
    elif [ "$t" -lt "$((IN_TICKS + H1_TICKS))" ]; then
        remaining_ticks=$((IN_TICKS + H1_TICKS - t))
        if [ "$EX_TYPE" = "double_inhale" ]; then
            phase="Sip in"
            pt=$((t - IN_TICKS))
            linear=$(( pt * 1000 / H1_TICKS ))
            progress=$(( 850 + $(ease "$linear") * 150 / 1000 ))
        else
            phase="Hold"
            progress=1000
        fi
        color="$COLOR_BRIGHT"
    elif [ "$t" -lt "$((IN_TICKS + H1_TICKS + EX_TICKS))" ]; then
        phase="Breathe out"
        remaining_ticks=$((IN_TICKS + H1_TICKS + EX_TICKS - t))
        pt=$((t - IN_TICKS - H1_TICKS))
        linear=$(( pt * 1000 / EX_TICKS ))
        progress=$((1000 - $(ease "$linear")))
        color="$COLOR_DEEP"
    else
        phase="Hold"
        remaining_ticks=$((CYCLE_TICKS - t))
        progress=0
        color="$COLOR_DEEP"
    fi

    # Compute scaled size
    max_half=$((BOX_W / 2))
    scaled_half=$((max_half * progress / 1000))
    [ "$scaled_half" -lt 1 ] && [ "$progress" -gt 0 ] && scaled_half=1

    # === Build frame ===
    padded=$(printf "%-${PANE_W}s" "")
    frame=""
    frame+="\033[1;1H${padded}"

    # Clear animation rows 2-8
    for r in 2 3 4 5 6 7 8; do
        frame+="\033[${r};1H${padded}"
    done

    case "$STYLE" in
        pulse)
            for i in 0 1 2 3 4; do
                case $i in
                    0|4) ratio=200 ;; 1|3) ratio=600 ;; 2) ratio=1000 ;;
                esac
                sr=$((i + 3))
                h=$((scaled_half * ratio / 1000))
                [ "$h" -gt 32 ] && h=32
                if [ "$h" -gt 0 ]; then
                    tw=$((h * 2))
                    c=$(((PANE_W - tw) / 2 + 1))
                    frame+="\033[${sr};${c}H${color}${GBAR_L[$h]}${GBAR_R[$h]}${RESET}"
                fi
            done
            ;;

        ripples)
            for dist in 0 1 2 3; do
                case $dist in
                    0) ratio=1000 ;; 1) ratio=750 ;; 2) ratio=500 ;; 3) ratio=250 ;;
                esac
                rw=$((scaled_half * ratio / 1000))
                [ "$rw" -gt 64 ] && rw=64
                if [ "$rw" -gt 0 ]; then
                    tw=$((rw * 2))
                    c=$(((PANE_W - tw) / 2 + 1))
                    case $dist in
                        0) lstr="${LSTR_H[$rw]}${LSTR_H[$rw]}" ;;
                        1) lstr="${LSTR_M[$rw]}${LSTR_M[$rw]}" ;;
                        2) lstr="${LSTR_L[$rw]}${LSTR_L[$rw]}" ;;
                        3) lstr="${LSTR_D[$rw]}${LSTR_D[$rw]}" ;;
                    esac
                    sr=$((5 - dist))
                    [ "$sr" -ge 2 ] && frame+="\033[${sr};${c}H${color}${lstr}${RESET}"
                    if [ "$dist" -gt 0 ]; then
                        sr=$((5 + dist))
                        [ "$sr" -le 8 ] && frame+="\033[${sr};${c}H${color}${lstr}${RESET}"
                    fi
                fi
            done
            ;;

        dots)
            center_col=$((PANE_W / 2))
            for dot in "${DOTS[@]}"; do
                IFS=':' read -r drow dcol <<< "$dot"
                abs_col=${dcol#-}
                if [ "$progress" -gt 0 ] && [ "$abs_col" -le "$progress" ]; then
                    sc=$((center_col + dcol * max_half / 1000))
                    sr=$((drow + 2))
                    if [ "$abs_col" -lt 150 ]; then
                        ch="✦"
                    elif [ "$abs_col" -lt 500 ]; then
                        ch="•"
                    else
                        ch="·"
                    fi
                    [ "$sc" -gt 0 ] && [ "$sc" -le "$PANE_W" ] && \
                        frame+="\033[${sr};${sc}H${color}${ch}${RESET}"
                fi
            done
            ;;

        wave)
            if [ "$scaled_half" -gt 0 ]; then
                sh2=$((scaled_half * scaled_half))
                for row_idx in 0 1 2; do
                    sr=$((7 - row_idx))
                    row_base=$((row_idx * 8))
                    row_str=""
                    any_char=0
                    for ((x=-scaled_half; x<=scaled_half; x++)); do
                        total_h=$((24 * (sh2 - x * x) / sh2))
                        row_h=$((total_h - row_base))
                        [ "$row_h" -lt 0 ] && row_h=0
                        [ "$row_h" -gt 8 ] && row_h=8
                        if [ "$row_h" -gt 0 ]; then
                            row_str+="${HBLK[$row_h]}"
                            any_char=1
                        else
                            row_str+=" "
                        fi
                    done
                    if [ "$any_char" -eq 1 ]; then
                        tw=$((scaled_half * 2 + 1))
                        c=$(((PANE_W - tw) / 2 + 1))
                        frame+="\033[${sr};${c}H${color}${row_str}${RESET}"
                    fi
                done
            fi
            ;;
    esac

    # Row 10: phase text with countdown
    remaining_s=$(( (remaining_ticks + TICK_RATE - 1) / TICK_RATE ))
    ptxt="$phase... ${remaining_s}s"
    pc=$(((PANE_W - ${#ptxt}) / 2 + 1))
    frame+="\033[10;1H${padded}\033[10;${pc}H${color}${ptxt}${RESET}"

    # Row 11: exercise name
    info="${EX_NAME}"
    ic=$(((PANE_W - ${#info}) / 2 + 1))
    frame+="\033[11;1H${padded}\033[11;${ic}H${COLOR_BRIGHT}${info}${RESET}"

    # Output
    printf '%b' "$frame"

    # 10 FPS tick
    sleep 0.1
    tick=$((tick + 1))
done
