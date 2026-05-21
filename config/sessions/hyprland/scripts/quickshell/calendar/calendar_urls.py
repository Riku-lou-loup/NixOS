#!/usr/bin/env python3
import json
import os
import sys

ENV_FILE = os.path.join(os.path.dirname(__file__), ".env")

def load_lines():
    if not os.path.exists(ENV_FILE):
        return []
    with open(ENV_FILE) as f:
        return f.readlines()

def get_urls():
    urls = []
    for line in load_lines():
        s = line.strip()
        if s.startswith("ICAL_URL=") and not s.startswith("ICAL_URL_"):
            urls.append({"key": "ICAL_URL", "url": s[9:]})
        elif s.startswith("ICAL_URL_") and "=" in s:
            key, _, val = s.partition("=")
            urls.append({"key": key, "url": val})
    return urls

def cmd_list():
    print(json.dumps(get_urls()))

def cmd_add(url):
    urls = get_urls()
    existing_keys = {u["key"] for u in urls}
    if "ICAL_URL" not in existing_keys:
        key = "ICAL_URL"
    else:
        i = 2
        while f"ICAL_URL_{i}" in existing_keys:
            i += 1
        key = f"ICAL_URL_{i}"
    with open(ENV_FILE, "a") as f:
        f.write(f"\n{key}={url}\n")
    print(json.dumps({"status": "ok"}))

def cmd_remove(key):
    lines = load_lines()
    new_lines = [l for l in lines if not l.strip().startswith(f"{key}=")]
    with open(ENV_FILE, "w") as f:
        f.writelines(new_lines)
    print(json.dumps({"status": "ok"}))

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    if cmd == "list":
        cmd_list()
    elif cmd == "add" and len(sys.argv) > 2:
        cmd_add(sys.argv[2])
    elif cmd == "remove" and len(sys.argv) > 2:
        cmd_remove(sys.argv[2])
