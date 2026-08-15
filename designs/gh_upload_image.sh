#!/usr/bin/env bash
# Upload a local image so it can be embedded in a GitHub issue/PR body via
# markdown, without any manual drag-and-drop step.
#
# Mechanism: this hits the same endpoint the GitHub web UI's paste/drag-drop
# uses (uploads.github.com/user-attachments/assets), authenticated with the
# same OAuth token `gh` already has (`gh auth token`) rather than a browser
# session. The returned URL 404s until it's actually referenced inside a
# saved issue/PR body (via `gh issue edit`/`gh issue comment`) — that save
# is what "activates" the asset. This is undocumented behavior (no public
# spec), verified working against a real public repo on 2026-08-13; if
# GitHub changes this endpoint, this script is the one place to fix it.
#
# Usage:
#   designs/gh_upload_image.sh <owner/repo> <path/to/image.png>
# Prints the resulting URL (https://github.com/user-attachments/assets/<uuid>)
# to stdout. Embed it with standard markdown: ![alt](<url>)
#
# Remember to actually reference the URL in a saved issue/comment body
# afterward — an upload that's never referenced stays a dangling 404.

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <owner/repo> <path/to/image>" >&2
  exit 1
fi

REPOSITORY="$1"
FILE="$2"

if [ ! -f "$FILE" ]; then
  echo "error: file not found: $FILE" >&2
  exit 1
fi

FILENAME=$(basename "$FILE")
case "$FILENAME" in
  *.png) MIME=image/png ;;
  *.jpg|*.jpeg) MIME=image/jpeg ;;
  *.gif) MIME=image/gif ;;
  *.webp) MIME=image/webp ;;
  *) echo "error: unsupported extension for $FILENAME (expected png/jpg/jpeg/gif/webp)" >&2; exit 1 ;;
esac

REPO_ID=$(gh api "repos/$REPOSITORY" --jq .id)
TOKEN=$(gh auth token)

# URL-encode the filename (query params can't contain raw spaces/special chars)
ENCODED_FILENAME=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$FILENAME")

RESPONSE=$(curl -s "https://uploads.github.com/user-attachments/assets?name=$ENCODED_FILENAME&content_type=$MIME&repository_id=$REPO_ID" \
  -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" --data-binary "@$FILE")

URL=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['url'])" 2>/dev/null)

if [ -z "$URL" ]; then
  echo "error: upload failed, response: $RESPONSE" >&2
  exit 1
fi

echo "$URL"
