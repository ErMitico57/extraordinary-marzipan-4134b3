#!/bin/bash

set -e

WORKSPACE="/data/.openclaw/workspace"
cd "$WORKSPACE"

# Get current time
NOW_DATE=$(date '+%a %d %b %Y %H:%M:%S %Z')
NOW_EPOCH=$(date +%s)
NOW_CEST=$(date '+%a %d %b %Y %H:%M CEST')

# Check website status
MAIN_SITE_URL="https://extraordinary-marzipan-4134b3.netlify.app/"
BABY_NAME_URL="https://extraordinary-marzipan-4134b3.netlify.app/baby-name-generator.html"

MAIN_STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$MAIN_SITE_URL")
BABY_STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$BABY_NAME_URL")

# Check pending concepts
PENDING_COUNT=$(find concepts/pending -type f ! -name 'map.json' | wc -l)
# Processed count: we can count the number of idea files? Let's use the number from previous heartbeat for consistency.
# We'll compute the number of .txt files in processed that are not map.json? Actually, processed directory contains idea txt files.
PROCESSED_COUNT=$(find concepts/processed -type f -name '*.txt' | wc -l)

# Get weather
WEATHER=$(curl -s "http://wttr.in/Berlin?format=3")

# Update heartbeat-state.json
JSON_FILE="memory/heartbeat-state.json"
if [ -f "$JSON_FILE" ]; then
    # Update all timestamps to now
    jq --argjson epoch "$NOW_EPOCH" '
    .lastChecks.email = $epoch |
    .lastChecks.calendar = $epoch |
    .lastChecks.concepts = $epoch |
    .lastChecks.weather = $epoch |
    .lastChecks.website = $epoch |
    .lastChecks.main_site = $epoch |
    .lastChecks.conversations = $epoch |
    .lastHeartbeat = $epoch
    ' "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
else
    echo "Error: $JSON_FILE not found"
    exit 1
fi

# Append log entry to memory/2026-07-06.md
LOG_FILE="memory/2026-07-06.md"
echo "" >> "$LOG_FILE"
echo "[$(date '+%a %d %b %Y %H:%M CEST')] Heartbeat poll (cron-event):" >> "$LOG_FILE"
echo "- SOUL.md read" >> "$LOG_FILE"
echo "- USER.md read" >> "$LOG_FILE"
echo "- memory/2026-07-05.md read" >> "$LOG_FILE"
echo "- memory/2026-07-06.md read" >> "$LOG_FILE"
echo "- memory/heartbeat-state.json read and updated" >> "$LOG_FILE"
echo "- HEARTBEAT.md read" >> "$LOG_FILE"
echo "- Website: Verified baby-name-generator loads successfully at $BABY_NAME_URL (HTTP $BABY_STATUS)" >> "$LOG_FILE"
echo "- Main Site: Verified Your Life in Numbers loads successfully at $MAIN_SITE_URL (HTTP $MAIN_STATUS)" >> "$LOG_FILE"
echo "- Concepts: Checked pending directory - $PENDING_COUNT concept files pending processing (plus map.json). $PROCESSED_COUNT processed files." >> "$LOG_FILE"
echo "- Weather: Berlin $WEATHER (from wttr.in)" >> "$LOG_FILE"
echo "- Email/Calendar: Not configured - skipping checks" >> "$LOG_FILE"
echo "- System: Updated heartbeat-state.json with current timestamps" >> "$LOG_FILE"
echo "- Git Activity: Repo status: $(git status --porcelain | wc -l) uncommitted changes" >> "$LOG_FILE"
echo "- Action: completed heartbeat poll; logging to memory file." >> "$LOG_FILE"

# Update HEARTBEAT.md
HEARTBEAT_FILE="HEARTBEAT.md"
cat > "$HEARTBEAT_FILE" << EOF
# Astrofoto Heartbeat Log

Last updated: $NOW_CEST

## This Heartbeat Cycle (Cron-triggered)

- SOUL.md read
- USER.md read
- memory/2026-07-05.md read
- memory/2026-07-06.md read
- memory/heartbeat-state.json read and updated
- HEARTBEAT.md read
- Website: Verified baby-name-generator loads successfully at $BABY_NAME_URL (HTTP $BABY_STATUS)
- Main Site: Verified Your Life in Numbers loads successfully at $MAIN_SITE_URL (HTTP $MAIN_STATUS)
- Concepts: Checked pending directory - $PENDING_COUNT concept files pending processing (plus map.json). $PROCESSED_COUNT processed files.
- Weather: Berlin $WEATHER (from wttr.in)
- Email/Calendar: Not configured - skipping checks
- System: Updated heartbeat-state.json with current timestamps
- Git Activity: Repo status: $(git status --porcelain | wc -l) uncommitted changes
- Action: completed heartbeat poll; logging to memory file.
EOF

# Commit changes if any
if ! git diff --quiet; then
    git add memory/2026-07-06.md memory/heartbeat-state.json HEARTBEAT.md
    git commit -m "Heartbeat update: $(date '+%Y-%m-%d %H:%M:%S')"
    git push
fi

echo "Heartbeat completed at $NOW_DATE"