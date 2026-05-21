#!/usr/bin/env bash
# Battery low notification daemon
WARNED_20=false
WARNED_10=false

while true; do
  capacity=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 100)
  status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo "Unknown")

  if [ "$status" != "Charging" ] && [ "$status" != "Full" ]; then
    if [ "$capacity" -le 10 ] && [ "$WARNED_10" = false ]; then
      notify-send -u critical "Battery Critical" "${capacity}% — plug in now!"
      WARNED_10=true
      WARNED_20=true
    elif [ "$capacity" -le 20 ] && [ "$WARNED_20" = false ]; then
      notify-send -u normal "Battery Low" "${capacity}% remaining"
      WARNED_20=true
    fi
  else
    WARNED_20=false
    WARNED_10=false
  fi

  sleep 60
done
