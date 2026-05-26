#!/bin/bash
API_KEY="${OPENWEATHER_API_KEY}"
LAT="${OPENWEATHER_CITY_LAT}"
LON="${OPENWEATHER_CITY_LON}"

WEATHER=$(curl -s "https://api.openweathermap.org/data/2.5/weather?lat=$LAT&lon=$LON&appid=$API_KEY&units=imperial")
UV=$(curl -s "https://api.openweathermap.org/data/2.5/uvi?lat=$LAT&lon=$LON&appid=$API_KEY")

TEMP=$(echo $WEATHER | jq '.main.temp | round')
CONDITION=$(echo $WEATHER | jq -r '.weather[0].main')
UV_INDEX=$(echo $UV | jq '.value | round')

case $CONDITION in
  "Clear")        ICON=$(printf "\ue30d") ;;
  "Clouds")       ICON=$(printf "\ue312") ;;
  "Rain")         ICON=$(printf "\ue318") ;;
  "Drizzle")      ICON=$(printf "\ue319") ;;
  "Thunderstorm") ICON=$(printf "\ue31d") ;;
  "Snow")         ICON=$(printf "\ue31a") ;;
  "Mist"|"Fog")   ICON=$(printf "\ue313") ;;
  *)              ICON=$(printf "\ue33d") ;;
esac

echo "$ICON ${TEMP}°F  UV: ${UV_INDEX}"