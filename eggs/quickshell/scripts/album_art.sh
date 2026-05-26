#!/bin/bash
TEMP_ART="/tmp/eww_album_art.png"
DEFAULT_ART="/home/storey/.config/quickshell/images/default_art.png"

# Get art URL from playerctl
ART_URL=$(playerctl metadata mpris:artUrl 2>/dev/null)

if [ -z "$ART_URL" ]; then
  echo "$DEFAULT_ART"
  exit 0
fi

# Handle file:// URLs
if [[ "$ART_URL" == file://* ]]; then
  ART_PATH="${ART_URL#file://}"
  convert "$ART_PATH" -resize 80x80^ -gravity center -extent 80x80 "$TEMP_ART"
else
  curl -s "$ART_URL" -o "$TEMP_ART"
  convert "$TEMP_ART" -resize 80x80^ -gravity center -extent 80x80 "$TEMP_ART"
fi

echo "$TEMP_ART"
