#!/usr/bin/env bash
socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

restart_topbar() {
  pkill -f "quickshell.*TopBar.qml" 2>/dev/null
  sleep 1
  quickshell -p ~/.config/hypr/scripts/quickshell/TopBar.qml &
}

move_workspaces_to_primary() {
  local primary="eDP-2"
  hyprctl workspaces -j 2>/dev/null | \
    python3 -c "
import sys, json
ws = json.load(sys.stdin)
primary = '$primary'
for w in ws:
    if w['monitor'] != primary:
        print(w['id'])
" 2>/dev/null | while read -r wsid; do
    hyprctl dispatch moveworkspacetomonitor "$wsid eDP-2" 2>/dev/null
  done
}

on_monitor_added() {
  local mon_name="$1"
  sleep 2

  # Apply highest refresh rate to the new monitor
  hyprctl keyword monitor ",highrr,auto,1.0" 2>/dev/null

  # Ensure the new monitor has a workspace so it doesn't show grey
  local empty_ws
  empty_ws=$(hyprctl workspaces -j 2>/dev/null | \
    python3 -c "
import sys, json
ws = json.load(sys.stdin)
used = {w['id'] for w in ws}
for i in range(1, 20):
    if i not in used:
        print(i)
        break
" 2>/dev/null)

  if [ -n "$empty_ws" ]; then
    hyprctl dispatch moveworkspacetomonitor "$empty_ws $mon_name" 2>/dev/null
    hyprctl dispatch workspace "$empty_ws" 2>/dev/null
  fi

  hyprctl dispatch dpms on 2>/dev/null
  restart_topbar
}

socat -u "UNIX-CONNECT:$socket" - 2>/dev/null | while IFS= read -r event; do
  case "$event" in
    monitoradded>>*)
      mon="${event#monitoradded>>}"
      on_monitor_added "$mon"
      ;;
    monitorremoved>>*)
      sleep 0.5
      move_workspaces_to_primary
      restart_topbar
      ;;
  esac
done
