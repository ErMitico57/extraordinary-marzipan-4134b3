#!/usr/bin/env bash
set -euo pipefail

# ------------------- CONFIG -------------------
CONCEPT_DIR="/data/.openclaw/workspace/concepts/pending"
PROCESSED_DIR="/data/.openclaw/workspace/concepts/processed"
SITE_DIR="/data/.openclaw/workspace/site_src"
GIT_REPO="/data/.openclaw/workspace"
LOG_FILE="/data/.openclaw/workspace/auto_growth.log"
NETLIFY_HOOK="https://api.netlify.com/build_hooks/6a43a5b756055a1f41b23713"
SITE_BASE="https://extraordinary-marzipan-4134b3.netlify.app"

log() { echo "[$(date)] $*" >> "$LOG_FILE"; }

# Ensure processed dir exists
mkdir -p "$PROCESSED_DIR"

log "=== Starting daily concept generation cycle ==="

# Find the first pending concept (FIFO order)
NEXT=$(ls -1 "${CONCEPT_DIR}"/*.txt 2>/dev/null | head -n1) || {
    log "No pending concepts found – exiting."
    exit 0
}
log "Selected concept: $NEXT"

# Extract title and description
TITLE_LINE=$(head -n1 "$NEXT")
DESC_LINE=$(head -n2 "$NEXT" | tail -n1)
# Remove prefix
TITLE=${TITLE_LINE#Concept: }
DESC=${DESC_LINE#Description: }

# Generate slug
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
DEST_FILE="${SITE_DIR}/${SLUG}.html"

# Create simple HTML page
cat > "$DEST_FILE" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>$TITLE</title>
<meta name="description" content="$DESC" />
<link rel="stylesheet" href="style.css" />
</head>
<body>
<div id="ads-container"></div>
<div class="content" style="max-width:800px;margin:2rem auto;padding:1rem;">
<h1>$TITLE</h1>
<p>$DESC</p>
</div>
<script>
  fetch('/_ads.html')
    .then(r => r.text())
    .then(html => { document.getElementById('ads-container').innerHTML = html; });
</script>
</body>
</html>
HTML

log "Generated page: $DEST_FILE"

# Git add, commit, push
cd "$GIT_REPO"
git commit -am "Add micro‑experience: $TITLE"
git commit -m "Add micro‑experience: $TITLE"
git push origin main:master
log "Pushed new page to GitHub"

# Trigger Netlify deploy via build hook
log "Calling Netlify build hook..."
curl -s -X POST "$NETLIFY_HOOK" >/dev/null
log "Netlify hook called."

# Build URL of the freshly published page
PAGE_URL="${SITE_BASE}/${SLUG}.html"
log "New page URL: $PAGE_URL"

# Move concept to processed
mv "$NEXT" "${PROCESSED_DIR}/"
log "Moved concept to processed folder."

log "=== Cycle completed ==="
