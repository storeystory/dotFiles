#!/bin/bash
API_KEY=$(cat ~/.local/state/syncthing/config.xml | grep -oP '(?<=<apikey>).*(?=</apikey>)')

# Check if Syncthing is running
HEALTH=$(curl -s -m 2 http://localhost:8384/rest/noauth/health 2>/dev/null)
if [ -z "$HEALTH" ]; then
  echo "󰓦"
  exit 0
fi

# Check connected devices
CONNECTED=$(curl -s -m 2 -H "X-API-Key: $API_KEY" http://localhost:8384/rest/system/connections | jq '[.connections | to_entries[] | select(.value.connected == true)] | length' 2>/dev/null)

# Check if any folders are syncing
SYNCING=$(curl -s -m 2 -H "X-API-Key: $API_KEY" http://localhost:8384/rest/db/completion | jq '.needBytes > 0' 2>/dev/null)

if [ "$SYNCING" = "true" ]; then
  # Animate by cycling through spinner frames based on current second
  SECOND=$(date +%S)
  FRAME=$(( SECOND % 2 ))
  case $FRAME in
    0) echo "󰑐 $CONNECTED" ;;
    1) echo "󰑙 $CONNECTED" ;;
  esac
else
  echo "󰓦 $CONNECTED"
fi