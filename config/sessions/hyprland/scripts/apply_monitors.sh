#!/usr/bin/env bash
settings="$HOME/.config/hypr/monitor_settings.json"
[ -f "$settings" ] || exit 0

python3 -c "
import json, subprocess, os, sys

with open(os.path.expanduser('~/.config/hypr/monitor_settings.json')) as f:
    monitors = json.load(f)

if not monitors:
    sys.exit(0)

cmds = []
for m in monitors:
    pos = 'auto' if len(monitors) == 1 else '{}x{}'.format(int(m['x']), int(m['y']))
    spec = '{},{}x{}@{},{},{}'.format(m['name'], m['resW'], m['resH'], m['rate'], pos, m['sysScale'])
    cmds.append('keyword monitor ' + spec)

if len(cmds) == 1:
    subprocess.run(['hyprctl', 'keyword', 'monitor',
        '{},{}x{}@{},auto,{}'.format(monitors[0]['name'], monitors[0]['resW'], monitors[0]['resH'],
                                     monitors[0]['rate'], monitors[0]['sysScale'])])
else:
    subprocess.run(['hyprctl', '--batch', ' ; '.join(cmds)])
"

sleep 0.8 && swww restore 2>/dev/null || true
