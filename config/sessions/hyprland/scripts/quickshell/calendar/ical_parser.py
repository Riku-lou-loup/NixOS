#!/usr/bin/env python3
"""
Parse an ICS calendar feed and output JSON for CalendarPopup.
Format: { "header": "N events", "lessons": [...], "link": "" }
Each event: { type, subject, time, room, start, end, width, is_compact }
"""
import json
import os
import sys
import re
import urllib.request
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo

CACHE_DIR = os.path.expanduser("~/.cache/quickshell/schedule")
CACHE_FILE = os.path.join(CACHE_DIR, "schedule.json")
ICAL_CACHE = os.path.join(CACHE_DIR, "calendar.ics")
CACHE_TTL = 600  # 10 minutes
TOTAL_WIDTH = 750  # pixel budget matching QML scaleRatio base

os.makedirs(CACHE_DIR, exist_ok=True)

def load_env():
    env_path = os.path.join(os.path.dirname(__file__), ".env")
    env = {}
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    env[k.strip()] = v.strip()
    return env

def fetch_ics(url, cache_file):
    if os.path.exists(cache_file):
        age = (datetime.now().timestamp() - os.path.getmtime(cache_file))
        if age < CACHE_TTL:
            with open(cache_file) as f:
                return f.read()
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as r:
            data = r.read().decode("utf-8", errors="replace")
        with open(cache_file, "w") as f:
            f.write(data)
        return data
    except Exception:
        if os.path.exists(cache_file):
            with open(cache_file) as f:
                return f.read()
        return None

def unfold(text):
    """Unfold multi-line ICS values."""
    return re.sub(r'\r?\n[ \t]', '', text)

def parse_dt(val, tzid=None):
    """Parse ICS DTSTART/DTEND value to UTC datetime."""
    val = val.strip()
    # All-day: DATE only
    if len(val) == 8:
        return datetime.strptime(val, "%Y%m%d").replace(tzinfo=timezone.utc), True
    # With Z = UTC
    if val.endswith("Z"):
        return datetime.strptime(val, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc), False
    # Floating with tzid
    dt = datetime.strptime(val[:15], "%Y%m%dT%H%M%S")
    if tzid:
        try:
            dt = dt.replace(tzinfo=ZoneInfo(tzid))
        except Exception:
            dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt, False

def parse_ics(text):
    text = unfold(text)
    events = []
    in_event = False
    current = {}
    for line in text.splitlines():
        if line.strip() == "BEGIN:VEVENT":
            in_event = True
            current = {}
        elif line.strip() == "END:VEVENT":
            in_event = False
            events.append(current)
        elif in_event and ":" in line:
            key, _, val = line.partition(":")
            # Handle params like DTSTART;TZID=Europe/Paris:20240101T090000
            if ";" in key:
                base_key = key.split(";")[0]
                # Extract TZID param
                tzid_match = re.search(r'TZID=([^;:]+)', key)
                tzid = tzid_match.group(1) if tzid_match else None
                current[base_key] = (val.strip(), tzid)
            else:
                current[key.strip()] = val.strip()
    return events

def get_today_events(ics_text, local_tz="Europe/Paris", target_date=None):
    tz = ZoneInfo(local_tz)
    now_local = datetime.now(tz)
    today = target_date if target_date is not None else now_local.date()
    
    events = parse_ics(ics_text)
    today_events = []
    
    for ev in events:
        raw_start = ev.get("DTSTART", "")
        raw_end = ev.get("DTEND", ev.get("DTSTART", ""))
        
        # Handle tuple (val, tzid) from parameterized keys
        start_tzid = end_tzid = None
        if isinstance(raw_start, tuple):
            raw_start, start_tzid = raw_start
        if isinstance(raw_end, tuple):
            raw_end, end_tzid = raw_end
        
        if not raw_start:
            continue
        
        try:
            dt_start, is_allday = parse_dt(raw_start, start_tzid)
            dt_end, _ = parse_dt(raw_end, end_tzid)
        except Exception:
            continue
        
        # Convert to local timezone for display
        start_local = dt_start.astimezone(tz)
        end_local = dt_end.astimezone(tz)
        
        # Check if event falls on today
        if is_allday:
            event_date = dt_start.date()
        else:
            event_date = start_local.date()
        
        if event_date != today:
            # Also check multi-day events
            if is_allday:
                end_date = dt_end.date()
                if not (dt_start.date() <= today < end_date):
                    continue
            else:
                if end_local.date() < today or start_local.date() > today:
                    continue
        
        summary = ev.get("SUMMARY", "No Title")
        # Decode escaped chars
        summary = summary.replace("\\,", ",").replace("\;", ";").replace("\\n", " ").replace("\\\\", "\\")
        
        location = ev.get("LOCATION", "")
        location = location.replace("\\,", ",").replace("\;", ";")
        
        if is_allday:
            time_str = "All day"
            start_epoch = int(dt_start.timestamp())
            end_epoch = int(dt_end.timestamp())
        else:
            time_str = f"{start_local.strftime('%H:%M')} - {end_local.strftime('%H:%M')}"
            start_epoch = int(dt_start.timestamp())
            end_epoch = int(dt_end.timestamp())
        
        today_events.append({
            "summary": summary,
            "location": location,
            "time_str": time_str,
            "start_epoch": start_epoch,
            "end_epoch": end_epoch,
            "is_allday": is_allday,
        })
    
    # Sort by start time
    today_events.sort(key=lambda e: e["start_epoch"])
    return today_events

def build_lessons(today_events):
    """Convert events to CalendarPopup lesson format with width allocation."""
    if not today_events:
        return []
    
    # Time range for the day (default 08:00 - 22:00 or span of events)
    all_day_events = [e for e in today_events if e["is_allday"]]
    timed_events = [e for e in today_events if not e["is_allday"]]
    
    lessons = []
    
    # All-day events shown as compact banners at the start
    for ev in all_day_events:
        lessons.append({
            "type": "class",
            "subject": ev["summary"],
            "time": "All day",
            "room": ev["location"],
            "start": ev["start_epoch"],
            "end": ev["end_epoch"],
            "width": 180,
            "is_compact": False,
            "desc": "",
        })
    
    if not timed_events:
        return lessons
    
    # Calculate time span
    day_start = min(e["start_epoch"] for e in timed_events)
    day_end = max(e["end_epoch"] for e in timed_events)
    total_seconds = max(day_end - day_start, 3600)  # at least 1h
    
    for i, ev in enumerate(timed_events):
        duration = max(ev["end_epoch"] - ev["start_epoch"], 900)  # min 15min
        width = max(int((duration / total_seconds) * TOTAL_WIDTH), 80)
        # The QML hides time/location for compact cards. A 90-minute class on a sparse
        # day can still be readable around ~110px, so keep the compact cutoff lower.
        is_compact = width < 100
        
        lessons.append({
            "type": "class",
            "subject": ev["summary"],
            "time": ev["time_str"],
            "room": ev["location"],
            "start": ev["start_epoch"],
            "end": ev["end_epoch"],
            "width": width,
            "is_compact": is_compact,
            "desc": "",
        })
        
        # Add gap between events
        if i < len(timed_events) - 1:
            next_ev = timed_events[i + 1]
            gap = next_ev["start_epoch"] - ev["end_epoch"]
            if gap > 300:  # > 5 min gap
                gap_width = max(int((gap / total_seconds) * TOTAL_WIDTH), 20)
                gap_mins = gap // 60
                lessons.append({
                    "type": "gap",
                    "subject": "",
                    "time": "",
                    "room": "",
                    "start": ev["end_epoch"],
                    "end": next_ev["start_epoch"],
                    "width": gap_width,
                    "is_compact": True,
                    "desc": f"{gap_mins}m",
                })
    
    return lessons

def main():
    env = load_env()

    # Collect all ICAL_URL, ICAL_URL_2, ICAL_URL_3, ... entries
    urls = []
    if env.get("ICAL_URL"):
        urls.append(env["ICAL_URL"])
    i = 2
    while env.get(f"ICAL_URL_{i}"):
        urls.append(env[f"ICAL_URL_{i}"])
        i += 1

    if not urls:
        print(json.dumps({"header": "No Calendar URL", "lessons": [], "link": ""}))
        return

    # Fetch and merge all calendars
    all_ics = []
    for idx, url in enumerate(urls):
        cache_file = os.path.join(CACHE_DIR, f"calendar_{idx}.ics")
        text = fetch_ics(url, cache_file)
        if text:
            all_ics.append(text)

    if not all_ics:
        print(json.dumps({"header": "Offline", "lessons": [], "link": ""}))
        return

    # Merge by concatenating VEVENT blocks from all calendars
    def extract_vevents(ics_text):
        events = []
        in_event = False
        block = []
        for line in ics_text.splitlines():
            if line.strip() == "BEGIN:VEVENT":
                in_event = True
                block = [line]
            elif line.strip() == "END:VEVENT":
                block.append(line)
                events.append("\n".join(block))
                in_event = False
                block = []
            elif in_event:
                block.append(line)
        return events

    merged_events = []
    for ics_text in all_ics:
        merged_events.extend(extract_vevents(ics_text))

    ics_text = "BEGIN:VCALENDAR\n" + "\n".join(merged_events) + "\nEND:VCALENDAR"
    
    # Detect local timezone from system
    local_tz = "Europe/Paris"
    tz_file = "/etc/localtime"
    if os.path.islink(tz_file):
        tz_path = os.readlink(tz_file)
        match = re.search(r'zoneinfo/(.+)', tz_path)
        if match:
            local_tz = match.group(1)

    # Accept optional date argument YYYY-MM-DD
    target_date = None
    if len(sys.argv) > 1:
        try:
            target_date = datetime.strptime(sys.argv[1], "%Y-%m-%d").date()
        except ValueError:
            pass

    today_events = get_today_events(ics_text, local_tz, target_date)
    lessons = build_lessons(today_events)

    n = len([l for l in lessons if l["type"] == "class"])
    tz = ZoneInfo(local_tz)
    actual_today = datetime.now(tz).date()
    if target_date and target_date != actual_today:
        from datetime import date as date_type
        label = target_date.strftime("%b %d")
        header = f"{n} event{'s' if n != 1 else ''} on {label}" if n > 0 else f"No events on {label}"
    else:
        header = f"{n} event{'s' if n != 1 else ''} today" if n > 0 else "No events today"
    
    result = {"header": header, "lessons": lessons, "link": ""}
    print(json.dumps(result))

if __name__ == "__main__":
    main()
