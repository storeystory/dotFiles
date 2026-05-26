#!/bin/bash
API_KEY="${NASA_API_KEY}"
CACHE_FILE="/tmp/nasa_apod_cache.json"
IMAGE_FILE="/tmp/nasa_apod.jpg"

# Always fetch fresh
curl -s "https://api.nasa.gov/planetary/apod?api_key=$API_KEY" > "$CACHE_FILE"

media_type=$(jq -r '.media_type' "$CACHE_FILE")
image_url=$(jq -r '.url' "$CACHE_FILE")

if [ "$media_type" = "image" ]; then
  curl -s "$image_url" -o /tmp/nasa_apod_raw.jpg
  magick /tmp/nasa_apod_raw.jpg -resize 348x200^ -gravity center -extent 348x200 "$IMAGE_FILE"
fi

title=$(jq -r '.title' "$CACHE_FILE" | tr -d '\n\r"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
explanation=$(jq -r '.explanation | .[0:600] + "..."' "$CACHE_FILE" | tr -d '\n\r"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

echo "{\"title\": \"$title\", \"explanation\": \"$explanation\", \"media_type\": \"$media_type\"}"