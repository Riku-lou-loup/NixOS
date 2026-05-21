#!/usr/bin/env bash
SETTINGS="$HOME/.config/hypr/idle_settings.json"
CONFIG="$HOME/.config/hypr/hypridle.conf"

LOCK=900
SCREEN_OFF=1800
SLEEP=3600

if [ -f "$SETTINGS" ]; then
    LOCK=$(python3 -c "import json; d=json.load(open('$SETTINGS')); print(d.get('lock', 900))" 2>/dev/null || echo 900)
    SCREEN_OFF=$(python3 -c "import json; d=json.load(open('$SETTINGS')); print(d.get('screen_off', 1800))" 2>/dev/null || echo 1800)
    SLEEP=$(python3 -c "import json; d=json.load(open('$SETTINGS')); print(d.get('sleep', 3600))" 2>/dev/null || echo 3600)
fi

mkdir -p "$(dirname "$CONFIG")"

cat > "$CONFIG" << EOF
general {
    lock_cmd = quickshell -p ~/.config/hypr/scripts/quickshell/Lock.qml
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = sleep 2 && hyprctl dispatch dpms on
}

listener {
    timeout = $LOCK
    on-timeout = loginctl lock-session
}

listener {
    timeout = $SCREEN_OFF
    on-timeout = hyprctl dispatch dpms off
    on-resume = sleep 1 && hyprctl dispatch dpms on
}

listener {
    timeout = $SLEEP
    on-timeout = systemctl suspend
}
EOF

pkill hypridle 2>/dev/null
sleep 0.3
hypridle &
disown
