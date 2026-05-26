#!/bin/bash

CACHE_FILE="/tmp/eww_tarot_cache"
CACHE_HTML_FILE="/tmp/eww_tarot_card.html"
CACHE_DATE_FILE="/tmp/eww_tarot_date"
CARDS_JSON="$HOME/.config/eww/scripts/tarot/cards.json"

TODAY=$(date +%Y-%m-%d)
CACHED_DATE=$(cat "$CACHE_DATE_FILE" 2>/dev/null)

if [ "$TODAY" != "$CACHED_DATE" ] || [ ! -f "$CACHE_FILE" ]; then
  echo "$TODAY" > "$CACHE_DATE_FILE"

  total=$(jq 'length' "$CARDS_JSON")
  idx=$(( RANDOM % total ))

  echo "{\"name\": ..., \"meaning\": ..., \"idx\": $idx}" > "$CACHE_FILE"

  name=$(jq -r ".[$idx].name" "$CARDS_JSON" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  meaning=$(jq -r ".[$idx].meaning" "$CARDS_JSON" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  card=$(jq -r ".[$idx].card" "$CARDS_JSON" | sed 's/^        //' | sed '/^[[:space:]]*$/d' | head -21)

  # Escape HTML special characters and join lines with | as separator
  card_oneline=$(echo "$card" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | python3 -c "import sys; print(sys.stdin.read().replace('\n', '\x01'), end='')")

  echo "<span foreground='#AC82E9'><tt>${card_oneline}</tt></span>" > "$CACHE_HTML_FILE"

  echo "{\"name\": $(echo "$name" | jq -Rs .), \"meaning\": $(echo "$meaning" | jq -Rs .), \"idx\": $idx}" > "$CACHE_FILE"
fi

cat "$CACHE_FILE"