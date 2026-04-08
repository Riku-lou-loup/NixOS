#!/bin/bash
# iCloud calendar via ICS - accepts optional date arg YYYY-MM-DD
CACHE_DIR="$HOME/.cache/quickshell/schedule"
CACHE_FILE="${CACHE_DIR}/schedule.json"
CACHE_TTL=600
PARSER="$HOME/.config/hypr/scripts/quickshell/calendar/ical_parser.py"
DATE_ARG="${1:-}"  # optional date YYYY-MM-DD

mkdir -p "$CACHE_DIR"

# For a specific date, use a per-date cache file
if [ -n "$DATE_ARG" ]; then
    CACHE_FILE="${CACHE_DIR}/schedule_${DATE_ARG}.json"
fi

run_parser() {
    if python3 "$PARSER" $DATE_ARG 2>/dev/null > "${CACHE_FILE}.tmp" && [ -s "${CACHE_FILE}.tmp" ]; then
        mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
    else
        rm -f "${CACHE_FILE}.tmp"
    fi
}

if [ -f "$CACHE_FILE" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
    if [ "$age" -gt "$CACHE_TTL" ]; then
        run_parser &
    fi
    cat "$CACHE_FILE"
else
    run_parser
    if [ -f "$CACHE_FILE" ]; then
        cat "$CACHE_FILE"
    else
        echo '{ "header": "Loading...", "lessons": [], "link": "" }'
    fi
fi
