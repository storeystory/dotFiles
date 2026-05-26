#!/bin/bash
PLAYER_STATUS=$(playerctl status 2>/dev/null)

if [ -z "$PLAYER_STATUS" ] || [ "$PLAYER_STATUS" = "No players found" ]; then
  echo '{"title": "Nothing playing", "artist": "", "status": "stopped", "position": 0, "length": 1}'
  exit 0
fi

TITLE=$(playerctl metadata title 2>/dev/null | head -c 30)
ARTIST=$(playerctl metadata artist 2>/dev/null | head -c 25)
STATUS=$(playerctl status 2>/dev/null)
POSITION=$(playerctl position 2>/dev/null | cut -d. -f1)
LENGTH=$(playerctl metadata mpris:length 2>/dev/null)

# Convert length from microseconds to seconds
LENGTH_SEC=$(( LENGTH / 1000000 ))
[ -z "$LENGTH_SEC" ] || [ "$LENGTH_SEC" -eq 0 ] && LENGTH_SEC=1

echo "{\"title\": \"$TITLE\", \"artist\": \"$ARTIST\", \"status\": \"$STATUS\", \"position\": $POSITION, \"length\": $LENGTH_SEC}"