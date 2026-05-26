# ── define ───────────────────────────────────────────────────────────
define() {
  if [ -z "$1" ]; then
    echo "Usage: define <word>"
    echo "       define --syn <word>"
    echo "       define --ant <word>"
    return 1
  fi

  local flag=""
  local word_arg="$1"

  if [ "$1" = "--syn" ] || [ "$1" = "--ant" ]; then
    if [ -z "$2" ]; then
      echo "Usage: define $1 <word>"
      return 1
    fi
    flag="$1"
    word_arg="$2"
  fi

  local response
  response=$(curl -s "https://api.dictionaryapi.dev/api/v2/entries/en/$word_arg")

  if echo "$response" | grep -q "No Definitions Found"; then
    echo -e "\e[38;2;252;70;73m✘ No definition found for '$word_arg'\e[0m"
    return 1
  fi

  local word phonetic
  word=$(echo "$response" | jq -r '.[0].word')
  phonetic=$(echo "$response" | jq -r '.[0].phonetic // ""')

  echo -e "\e[38;2;172;130;233m\e[1m$word\e[0m \e[38;2;138;125;110m$phonetic\e[0m"
  echo -e "\e[38;2;172;130;233m$(printf '%.0s─' {1..40})\e[0m"

  if [ "$flag" = "--syn" ]; then
    echo -e "\e[38;2;172;130;233m\e[1mSynonyms\e[0m"
    echo ""
    echo "$response" | jq -r '.[0].meanings[] | .partOfSpeech as $pos | select(.synonyms | length > 0) | "\($pos)|\(.synonyms | join(", "))"' | while IFS='|' read -r pos syns; do
      echo -e "\e[38;2;138;125;110m[\e[38;2;172;130;233m$pos\e[38;2;138;125;110m]\e[0m"
      echo -e "  \e[38;2;216;202;184m$syns\e[0m"
      echo ""
    done
    return 0
  fi

  if [ "$flag" = "--ant" ]; then
    echo -e "\e[38;2;172;130;233m\e[1mAntonyms\e[0m"
    echo ""
    echo "$response" | jq -r '.[0].meanings[] | .partOfSpeech as $pos | select(.antonyms | length > 0) | "\($pos)|\(.antonyms | join(", "))"' | while IFS='|' read -r pos ants; do
      echo -e "\e[38;2;138;125;110m[\e[38;2;172;130;233m$pos\e[38;2;138;125;110m]\e[0m"
      echo -e "\e[38;2;216;202;184m  $ants\e[0m"
      echo ""
    done
    return 0
  fi

  echo "$response" | jq -r '.[0].meanings[] | .partOfSpeech as $pos | .definitions[:3][] | "\($pos)|\(.definition)|\(.example // "")"' | while IFS='|' read -r pos def example; do
    echo -e "\e[38;2;138;125;110m[\e[38;2;172;130;233m$pos\e[38;2;138;125;110m]\e[0m"
    echo -e "  \e[38;2;216;202;184m$def\e[0m"
    if [ -n "$example" ]; then
      echo -e "  \e[38;2;138;125;110m\"$example\"\e[0m"
    fi
    echo ""
  done
}

# ── nounverbed ───────────────────────────────────────────────────────
nounverbed() {
  _get_random_noun() {
    local letter=$(echo {a..z} | tr ' ' '\n' | shuf | head -1)
    local words
    words=$(curl -s "https://api.datamuse.com/words?sp=${letter}*&topics=common&md=p&max=20" | \
      jq -r '[.[] | select(.tags != null and (.tags | contains(["n"])))] | .[].word')
    echo "$words" | shuf | head -1
  }

  _get_random_verb() {
    local letter=$(echo {a..z} | tr ' ' '\n' | shuf | head -1)
    local words
    words=$(curl -s "https://api.datamuse.com/words?sp=${letter}*&topics=common&md=p&max=20" | \
      jq -r '[.[] | select(.tags != null and (.tags | contains(["v"])))] | .[].word')
    echo "$words" | shuf | head -1
  }
  _get_pos() {
    local word=$1
    curl -s "https://api.dictionaryapi.dev/api/v2/entries/en/$word" | \
      jq -r '.[0].meanings[0].partOfSpeech // "unknown"' 2>/dev/null
  }

  _to_past_tense() {
    local verb=$1
    if [[ $verb =~ e$ ]]; then
      echo "${verb}d"
    elif [[ $verb =~ [^aeiou][aeiou][^aeiou]$ ]]; then
      echo "${verb: -1}${verb: -1}ed" | sed "s/^/${verb:0:-1}/"
    else
      echo "${verb}ed"
    fi
  }

  # echo -e "\e[38;2;138;125;110mSearching the void...\e[0m"

  local noun verb past_tense attempts=0

  while [ -z "$noun" ] && [ $attempts -lt 10 ]; do
    noun=$(_get_random_noun)
    ((attempts++))
  done

  attempts=0
  while [ -z "$verb" ] && [ $attempts -lt 10 ]; do
    verb=$(_get_random_verb)
    ((attempts++))
  done

  if [ -z "$noun" ] || [ -z "$verb" ]; then
    echo -e "\e[38;2;252;70;73m✘ The API gods were displeased. Try again.\e[0m"
    return 1
  fi

  past_tense=$(_to_past_tense "$verb")

  echo ""
  echo -e "\e[38;2;172;130;233m\e[1m${noun^} ${past_tense}.\e[0m"
  echo ""
}

# ── mkcd ─────────────────────────────────────────────────────────────
mkcd() {
  if [ -z "$1" ]; then
    echo "Usage: mkcd <dirname>"
    return 1
  fi
  mkdir -p "$1" && cd "$1"
}
# -- cdls ───────────────────────────────────────────────────────────
cdls() {
  if [ -z "$1" ]; then
    cd ~ && eza --icons --group-directories-first
  else
    cd "$1" && eza --icons --group-directories-first
  fi
}
# ── myip ─────────────────────────────────────────────────────────────
myip() {
  local local_ip public_ip
  local_ip=$(ip route get 1 | awk '{print $7; exit}')
  public_ip=$(curl -s https://api.ipify.org)

  echo ""
  echo -e "\e[38;2;172;130;233m\e[1mIP Addresses\e[0m"
  echo -e "\e[38;2;172;130;233m$(printf '%.0s─' {1..40})\e[0m"
  echo -e "\e[38;2;138;125;110mLocal: \e[38;2;216;202;184m$local_ip\e[0m"
  echo -e "\e[38;2;138;125;110mPublic:\e[38;2;216;202;184m $public_ip\e[0m"
  echo ""
}

# ── nasa ─────────────────────────────────────────────────────────────
nasa() {
  local API_KEY="${NASA_API_KEY}"
  local response image_url title explanation media_type

  echo -e "\e[38;2;138;125;110mContacting NASA...\e[0m"

  response=$(curl -s "https://api.nasa.gov/planetary/apod?api_key=$API_KEY")

  title=$(echo "$response" | jq -r '.title')
  explanation=$(echo "$response" | jq -r '.explanation')
  media_type=$(echo "$response" | jq -r '.media_type')
  image_url=$(echo "$response" | jq -r '.url')

  echo ""
  echo -e "\e[38;2;172;130;233m\e[1m$title\e[0m"
  echo -e "\e[38;2;172;130;233m$(printf '%.0s─' {1..40})\e[0m"

  if [ "$media_type" = "image" ]; then
    local tmp_file="/tmp/nasa_apod.jpg"
    curl -s "$image_url" -o "$tmp_file"
    kitty +kitten icat --align left "$tmp_file"
    echo ""
  else
    echo -e "\e[38;2;138;125;110m[Today's APOD is a video — $image_url]\e[0m"
    echo ""
  fi

  echo "$explanation" | fold -s -w 80 | while IFS= read -r line; do
    echo -e "\e[38;2;216;202;184m$line\e[0m"
  done
  echo ""
}

# ── roll ─────────────────────────────────────────────────────────────
roll() {
  if [ -z "$1" ]; then
    echo "Usage: roll <expression> (e.g. roll 2d6+1d4+2)"
    return 1
  fi

  local input="${1,,}"
  local total=0
  local output_parts=()
  local all_rolls=()

  if ! [[ "$input" =~ ^[0-9d+]+$ ]]; then
    echo -e "\e[38;2;252;70;73m✘ Invalid format. Use NdN+NdN+N syntax, e.g. roll 2d6+1d4+2\e[0m"
    return 1
  fi

  echo ""
  echo -e "\e[38;2;172;130;233m\e[1mRolling ${1}...\e[0m"
  echo -e "\e[38;2;172;130;233m$(printf '%.0s─' {1..40})\e[0m"

  IFS='+' read -ra parts <<< "$input"

  for part in "${parts[@]}"; do
    if [[ "$part" =~ ^([0-9]+)d([0-9]+)$ ]]; then
      local count="${BASH_REMATCH[1]}"
      local sides="${BASH_REMATCH[2]}"

      if [ "$sides" -lt 2 ]; then
        echo -e "\e[38;2;252;70;73m✘ Dice must have at least 2 sides\e[0m"
        return 1
      fi

      local rolls=()
      local subtotal=0
      for (( i=0; i<count; i++ )); do
        local result=$(( RANDOM % sides + 1 ))
        rolls+=("$result")
        subtotal=$(( subtotal + result ))
      done

      all_rolls+=("${count}d${sides}: [${rolls[*]}] = ${subtotal}")
      total=$(( total + subtotal ))

    elif [[ "$part" =~ ^([0-9]+)$ ]]; then
      total=$(( total + part ))
      all_rolls+=("Bonus: +${part}")
    else
      echo -e "\e[38;2;252;70;73m✘ Invalid component: $part\e[0m"
      return 1
    fi
  done

  for roll_line in "${all_rolls[@]}"; do
    echo -e "\e[38;2;138;125;110m${roll_line}\e[0m"
  done

  echo -e "\e[38;2;172;130;233m$(printf '%.0s─' {1..40})\e[0m"
  echo -e "\e[38;2;138;125;110mTotal: \e[38;2;172;130;233m\e[1m${total}\e[0m"
  echo ""
}

# ── calc ─────────────────────────────────────────────────────────────
calc() {
  if [ -z "$1" ]; then
    echo "Usage: calc <expression> (e.g. calc 6+6)"
    return 1
  fi

  local result
  result=$(echo "scale=4; $1" | bc -l 2>&1)

  if [ $? -ne 0 ]; then
    echo -e "\e[38;2;252;70;73m✘ Invalid expression\e[0m"
    return 1
  fi

  # Strip trailing zeros after decimal point
  result=$(echo "$result" | sed 's/\.0*$//;s/\(\.[0-9]*[1-9]\)0*/\1/')

  echo ""
  echo -e "\e[38;2;172;130;233m\e[1m$1 = $result\e[0m"
  echo ""
}

# ── tarot ─────────────────────────────────────────────────────────────
_tarot_display_card() {
  local idx=$1
  local colorize=${2:-1}
  local CARDS_JSON="$HOME/.config/eww/scripts/tarot/cards.json"
  local name=$(jq -r ".[$idx].name" "$CARDS_JSON")
  local meaning=$(jq -r ".[$idx].meaning" "$CARDS_JSON")
  local card=$(jq -r ".[$idx].card" "$CARDS_JSON" | sed 's/^        //')

  local name_wrapped=$(echo "$name" | fold -s -w 21 | while IFS= read -r line; do printf "%-21s\n" "$line"; done)
  local meaning_wrapped=$(echo "$meaning" | fold -s -w 21 | while IFS= read -r line; do printf "%-21s\n" "$line"; done)
  local separator=$(printf "%-21s" "─────────────────────")

  if [ "$colorize" = "1" ]; then
    printf "\e[38;2;172;130;233m%s\e[0m\n" "$card"
    printf "\e[38;2;172;130;233m%s\e[0m\n" "$separator"
    printf "\e[38;2;216;202;184m\e[1m%s\e[0m\n" "$name_wrapped"
    printf "\e[38;2;138;125;110m%s\e[0m\n" "$meaning_wrapped"
  else
    printf "%s\n" "$card"
    printf "%s\n" "$separator"
    printf "%s\n" "$name_wrapped"
    printf "%s\n" "$meaning_wrapped"
  fi

  local lines=$(printf "%s\n%s\n%s\n%s" "$card" "$separator" "$name_wrapped" "$meaning_wrapped" | wc -l)
  local padding=$(( 30 - lines ))
  for (( p=0; p<padding; p++ )); do
    printf "%-21s\n" " "
  done
}

tarot() {
  local CARDS_JSON="$HOME/.config/eww/scripts/tarot/cards.json"
  local CACHE_IDX="/tmp/eww_tarot_cache"

  if [ -z "$1" ]; then
    echo "Usage:"
    echo "  tarot <number>     — draw N random cards"
    echo "  tarot <card-name>  — display a specific card (e.g. tarot the-world)"
    echo "  tarot -t|today     — display today's card of the day"
    return 0
  fi

  if [ "$1" = "-t" ] || [ "$1" = "today" ]; then
    if [ ! -f "$CACHE_IDX" ]; then
      echo -e "\e[38;2;252;70;73m✘ No card of the day found. Has the widget loaded today?\e[0m"
      return 1
    fi
    local idx=$(jq -r '.idx' "$CACHE_IDX" 2>/dev/null)
    if [ -z "$idx" ] || [ "$idx" = "null" ]; then
      echo -e "\e[38;2;252;70;73m✘ Could not read today's card index.\e[0m"
      return 1
    fi
    _tarot_display_card "$idx"
    return 0
  fi

  if [[ "$1" =~ ^[0-9]+$ ]]; then
    local count=$1
    local drawn=()
    local total=$(jq 'length' "$CARDS_JSON")
    while [ ${#drawn[@]} -lt $count ]; do
      local idx=$(( RANDOM % total ))
      local already=0
      for i in "${drawn[@]}"; do
        [ "$i" -eq "$idx" ] && already=1 && break
      done
      [ $already -eq 0 ] && drawn+=("$idx")
    done

    local tmp_dir=$(mktemp -d)
    local i=0
    for idx in "${drawn[@]}"; do
      _tarot_display_card "$idx" 0 > "$tmp_dir/card_$i"
      i=$(( i + 1 ))
    done

    local j=0
    while [ $j -lt $count ]; do
      local files=()
      for k in 0 1 2; do
        local n=$(( j + k ))
        if [ $n -lt $count ]; then
          files+=("$tmp_dir/card_$n")
        fi
      done
      local sep_file="$tmp_dir/sep"
      local num_lines=$(wc -l < "${files[0]}")
      > "$sep_file"
      for (( s=0; s<num_lines; s++ )); do
        echo " | " >> "$sep_file"
      done
      local output
      case ${#files[@]} in
        1) output=$(paste -d'\0' "${files[0]}") ;;
        2) output=$(paste -d'\0' "${files[0]}" "$sep_file" "${files[1]}") ;;
        3) output=$(paste -d'\0' "${files[0]}" "$sep_file" "${files[1]}" "$sep_file" "${files[2]}") ;;
      esac
      echo "$output" | while IFS= read -r line; do
        printf "\e[38;2;172;130;233m%s\e[0m\n" "$line"
      done
      j=$(( j + 3 ))
    done
    rm -rf "$tmp_dir"
    return 0
  fi

  local search=$(echo "$1" | tr '-' ' ' | tr '[:upper:]' '[:lower:]')
  local idx=$(jq -r "to_entries[] | select(.value.name | ascii_downcase | . == \"$search\") | .key" "$CARDS_JSON" | head -1)

  if [ -z "$idx" ]; then
    idx=$(jq -r "to_entries[] | select(.value.name | ascii_downcase | contains(\"$search\")) | .key" "$CARDS_JSON" | head -1)
  fi

  if [ -z "$idx" ]; then
    echo -e "\e[38;2;252;70;73m✘ Card not found: '$1'\e[0m"
    echo -e "\e[38;2;138;125;110mTry: tarot the-fool, tarot 9-of-wands, tarot queen-of-cups\e[0m"
    return 1
  fi

  _tarot_display_card "$idx"
}
# ── saveclip ─────────────────────────────────────────────────────────
saveclip() {
  local filename="${1:-$(date +%Y-%m-%d_%H-%M-%S)}.png"
  local dest=~/Pictures/Screenshots/$filename
  mkdir -p ~/Pictures/Screenshots
  wl-paste --type image/png > "$dest"
  echo -e "\e[38;2;172;130;233m✓ Saved to $dest\e[0m"
}
# ── newvault ──────────────────────────────────────────────────────────
newvault() {
if [ -z "$1" ]; then
    echo -e "\e[38;2;172;130;233m\e[1mNew Obsidian Vault\e[0m"
    echo -e "\e[38;2;172;130;233m$(printf '%.0s─' {1..40})\e[0m"
    printf "\e[38;2;138;125;110mVault name: \e[38;2;216;202;184m"
    read name
    printf "\e[0m"
    if [ -z "$name" ]; then
      echo -e "\e[38;2;252;70;73m✘ No name provided\e[0m"
      return 1
    fi
    # Shift so the rest of the function uses the read name
    set -- "$name"
  fi

# Warn if vault name contains spaces
  if [[ "$1" == *" "* ]]; then
    echo -e "\e[38;2;252;70;73m⚠ Vault name contains spaces, which may cause issues with some Obsidian plugins.\e[0m"
    printf "\e[38;2;138;125;110mContinue anyway? [y/N]: \e[38;2;216;202;184m"
    read confirm
    printf "\e[0m"
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo -e "\e[38;2;252;70;73m✘ Aborted\e[0m"
      return 1
    fi
  fi

  # List all vaults
    if [ "$1" = "--list" ]; then
      echo ""
      echo -e "\e[38;2;172;130;233m\e[1mObsidian Vaults\e[0m"
      echo -e "\e[38;2;172;130;233m$(printf '%.0s─' {1..40})\e[0m"
      jq -r '.vaults[] | .path' "$HOME/.config/obsidian/obsidian.json" | while IFS= read -r path; do
        local vaultname=$(basename "$path")
        echo -e "\e[38;2;216;202;184m\e[1m$vaultname\e[0m \e[38;2;138;125;110m$path\e[0m"
      done
      echo ""
      return 0
    fi

  # Remove a vault from Obsidian's config
    if [ "$1" = "--remove" ]; then
      if [ -z "$2" ]; then
        echo "Usage: newvault --remove <name>"
        return 1
      fi

      local name="$2"
      local obsidian_config="$HOME/.config/obsidian/obsidian.json"

      # Find the vault ID by matching the path basename
      local vault_id=$(jq -r --arg name "$name" \
        '.vaults | to_entries[] | select(.value.path | split("/") | last == $name) | .key' \
        "$obsidian_config")

      if [ -z "$vault_id" ]; then
        echo -e "\e[38;2;252;70;73m✘ No vault named '$name' found in Obsidian config\e[0m"
        return 1
      fi

      local vault_path=$(jq -r --arg id "$vault_id" '.vaults[$id].path' "$obsidian_config")

      # Remove from obsidian.json
      local tmp=$(mktemp)
      jq --arg id "$vault_id" 'del(.vaults[$id])' "$obsidian_config" > "$tmp" && mv "$tmp" "$obsidian_config"

      echo -e "\e[38;2;172;130;233m✓ Vault '$name' removed from Obsidian\e[0m"
      echo -e "\e[38;2;138;125;110mFiles are still on disk at: $vault_path\e[0m"
      return 0
    fi

  # Rename a vault
  if [ "$1" = "--rename" ]; then
    if [ -z "$2" ] || [ -z "$3" ]; then
      echo "Usage: newvault --rename <old-name> <new-name>"
      return 1
    fi

    local old_name="$2"
    local new_name="$3"
    local obsidian_config="$HOME/.config/obsidian/obsidian.json"

    # Find the vault ID by matching the path basename
    local vault_id=$(jq -r --arg name "$old_name" \
      '.vaults | to_entries[] | select(.value.path | split("/") | last == $name) | .key' \
      "$obsidian_config")

    if [ -z "$vault_id" ]; then
      echo -e "\e[38;2;252;70;73m✘ No vault named '$old_name' found in Obsidian config\e[0m"
      return 1
    fi

    local old_path=$(jq -r --arg id "$vault_id" '.vaults[$id].path' "$obsidian_config")
    local new_path="$(dirname "$old_path")/$new_name"

    if [ -d "$new_path" ]; then
      echo -e "\e[38;2;252;70;73m✘ A folder named '$new_name' already exists at $(dirname "$old_path")\e[0m"
      return 1
    fi

    # Rename on disk
    mv "$old_path" "$new_path"

    # Update obsidian.json
    local tmp=$(mktemp)
    jq --arg id "$vault_id" \
       --arg path "$new_path" \
       '.vaults[$id].path = $path' \
       "$obsidian_config" > "$tmp" && mv "$tmp" "$obsidian_config"

    echo -e "\e[38;2;172;130;233m✓ Vault '$old_name' renamed to '$new_name'\e[0m"
    echo -e "\e[38;2;138;125;110mNew path: $new_path\e[0m"
    return 0
  fi

  # Delete a vault
  if [ "$1" = "--delete" ]; then
    if [ -z "$2" ]; then
      echo "Usage: newvault --delete <name>"
      return 1
    fi

    local name="$2"
    local obsidian_config="$HOME/.config/obsidian/obsidian.json"

    # Find the vault ID
    local vault_id=$(jq -r --arg name "$name" \
      '.vaults | to_entries[] | select(.value.path | split("/") | last == $name) | .key' \
      "$obsidian_config")

    if [ -z "$vault_id" ]; then
      echo -e "\e[38;2;252;70;73m✘ No vault named '$name' found in Obsidian config\e[0m"
      return 1
    fi

    local vault_path=$(jq -r --arg id "$vault_id" '.vaults[$id].path' "$obsidian_config")

    # Confirmation prompt
    echo -e "\e[38;2;252;70;73m⚠ This will permanently delete '$name' and all its contents.\e[0m"
    echo -e "\e[38;2;138;125;110mPath: $vault_path\e[0m"
    printf "\e[38;2;252;70;73mType the vault name to confirm: \e[38;2;216;202;184m"
    read confirm
    printf "\e[0m"

    if [ "$confirm" != "$name" ]; then
      echo -e "\e[38;2;252;70;73m✘ Name did not match, aborted\e[0m"
      return 1
    fi

    # Remove from obsidian.json
    local tmp=$(mktemp)
    jq --arg id "$vault_id" 'del(.vaults[$id])' "$obsidian_config" > "$tmp" && mv "$tmp" "$obsidian_config"

    # Delete files
    rm -rf "$vault_path"

    echo -e "\e[38;2;172;130;233m✓ Vault '$name' deleted\e[0m"
    return 0
  fi

    # Open an existing vault
  if [ "$1" = "--open" ]; then
    if [ -z "$2" ]; then
      echo "Usage: newvault --open <name>"
      return 1
    fi

    local name="$2"
    local obsidian_config="$HOME/.config/obsidian/obsidian.json"

    # Find the vault by name
    local vault_id=$(jq -r --arg name "$name" \
      '.vaults | to_entries[] | select(.value.path | split("/") | last == $name) | .key' \
      "$obsidian_config")

    if [ -z "$vault_id" ]; then
      echo -e "\e[38;2;252;70;73m✘ No vault named '$name' found in Obsidian config\e[0m"
      echo -e "\e[38;2;138;125;110mTip: use 'newvault --list' to see all vaults\e[0m"
      return 1
    fi

    local vault_path=$(jq -r --arg id "$vault_id" '.vaults[$id].path' "$obsidian_config")

    pkill -x obsidian 2>/dev/null
    sleep 1
    xdg-open "obsidian://open?path=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$vault_path'))")" &
    disown

    echo -e "\e[38;2;172;130;233m✓ Opening vault '$name'\e[0m"
    return 0
  fi

  local name="$1"
  local template="$HOME/Documents/Template-Vault"
  local obsidian_config="$HOME/.config/obsidian/obsidian.json"

  # If a path is passed, use it; otherwise default to ~/SyncThing
  if [ -n "$2" ]; then
    local dest="$2/$name"
  else
    local dest="$HOME/SyncThing/$name"
  fi

  # If vault already exists, just register and open it
  if [ -d "$dest" ]; then
    echo -e "\e[38;2;138;125;110mVault '$name' already exists, opening...\e[0m"
  else
    if [ ! -d "$template" ]; then
      echo -e "\e[38;2;252;70;73m✘ Template vault not found at $template\e[0m"
      return 1
    fi
    echo -e "\e[38;2;138;125;110mCreating vault '$name'...\e[0m"
    cp -r "$template" "$dest"
  fi

  # Generate a random hex ID and timestamp
  local vault_id=$(openssl rand -hex 8)
  local timestamp=$(date +%s%3N)

  # Kill Obsidian, register vault, reopen
  pkill -x obsidian 2>/dev/null
  sleep 1

  # Add vault to obsidian.json
  local tmp=$(mktemp)
  jq --arg id "$vault_id" \
     --arg path "$dest" \
     --argjson ts "$timestamp" \
     '.vaults[$id] = {"path": $path, "ts": $ts}' \
     "$obsidian_config" > "$tmp" && mv "$tmp" "$obsidian_config"

  sleep 0.5
  xdg-open "obsidian://open?path=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$dest'))")" &
  disown

  echo -e "\e[38;2;172;130;233m✓ Vault '$name' opened at $dest\e[0m"
}
# ── upload ───────────────────────────────────────────────────────────
upload() {
  if [ -z "$1" ]; then
    echo "Usage: upload <file>"
    return 1
  fi

  if [ ! -f "$1" ]; then
    echo -e "\e[38;2;252;70;73m✘ File not found: '$1'\e[0m"
    return 1
  fi

  echo -e "\e[38;2;138;125;110mUploading '$1'...\e[0m"

  local url
  url=$(curl -sF "file=@$1" https://0x0.st)

  if [ -z "$url" ]; then
    echo -e "\e[38;2;252;70;73m✘ Upload failed\e[0m"
    return 1
  fi

  echo -e "\e[38;2;172;130;233m✓ Uploaded: \e[38;2;216;202;184m$url\e[0m"
  echo "$url" | wl-copy
  echo -e "\e[38;2;138;125;110m(URL copied to clipboard)\e[0m"
}
# ── make-gist ────────────────────────────────────────────────────────
make-gist() {
  if [ -z "$1" ]; then
    echo "Usage: make-gist <file1> [file2] [file3] ..."
    return 1
  fi

  if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "\e[38;2;252;70;73m✘ GITHUB_TOKEN not set in secrets.sh\e[0m"
    return 1
  fi

  echo -e "\e[38;2;138;125;110mCreating gist...\e[0m"

  # Build the JSON payload with all files
  local files_json="{}"
  for file in "$@"; do
    if [ ! -f "$file" ]; then
      echo -e "\e[38;2;252;70;73m✘ File not found: '$file'\e[0m"
      return 1
    fi
    local filename=$(basename "$file")
    local content=$(cat "$file")
    files_json=$(echo "$files_json" | jq --arg name "$filename" --arg content "$content" \
      '. + {($name): {"content": $content}}')
  done

  # Ask for description
  printf "\e[38;2;138;125;110mDescription (optional): \e[38;2;216;202;184m"
  read description
  printf "\e[0m"

  # Ask for public or secret
  printf "\e[38;2;138;125;110mPublic gist? [y/N]: \e[38;2;216;202;184m"
  read public_choice
  printf "\e[0m"
  local public="false"
  [[ "$public_choice" == "y" || "$public_choice" == "Y" ]] && public="true"

  # Build final payload
  local payload
  payload=$(jq -n \
    --arg desc "$description" \
    --argjson public "$public" \
    --argjson files "$files_json" \
    '{"description": $desc, "public": $public, "files": $files}')

  # Upload to GitHub
  local response
  response=$(curl -s \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$payload" \
    https://api.github.com/gists)

  local url
  url=$(echo "$response" | jq -r '.html_url')

  if [ -z "$url" ] || [ "$url" = "null" ]; then
    echo -e "\e[38;2;252;70;73m✘ Failed to create gist\e[0m"
    echo "$response" | jq -r '.message // "Unknown error"'
    return 1
  fi

  echo -e "\e[38;2;172;130;233m✓ Gist created: \e[38;2;216;202;184m$url\e[0m"
  echo "$url" | wl-copy
  echo -e "\e[38;2;138;125;110m(URL copied to clipboard)\e[0m"
}
# ── notify ───────────────────────────────────────────────────────────
notify() {
  if [ -z "$1" ]; then
    echo "Usage: notify <command> [args...]"
    return 1
  fi

  local device_id=$(kdeconnect-cli -l --id-only 2>/dev/null | head -1)

  if [ -z "$device_id" ]; then
    echo -e "\e[38;2;252;70;73m✘ No KDE Connect device found\e[0m"
    return 1
  fi

  # Run the command
  echo -e "\e[38;2;138;125;110mRunning: $@\e[0m"
  "${@}"
  local exit_code=$?

  # Send ping with result
  if [ $exit_code -eq 0 ]; then
    kdeconnect-cli --device "$device_id" --ping-msg "✓ Done: $*"
  else
    kdeconnect-cli --device "$device_id" --ping-msg "✘ Failed (exit $exit_code): $*"
  fi

  return $exit_code
}
# ── send ─────────────────────────────────────────────────────────────
send() {
  if [ -z "$1" ]; then
    echo "Usage: send <file>         # send a file to phone"
    echo "       send <text>         # send text to phone clipboard"
    echo "       send --clip         # send current clipboard to phone"
    return 1
  fi

  local device_id=$(kdeconnect-cli -l --id-only 2>/dev/null | head -1)

  if [ -z "$device_id" ]; then
    echo -e "\e[38;2;252;70;73m✘ No KDE Connect device found\e[0m"
    return 1
  fi

  if [ "$1" = "--clip" ]; then
    local text=$(wl-paste)
    kdeconnect-cli --device "$device_id" --share-text "$text"
    echo -e "\e[38;2;172;130;233m✓ Clipboard sent to phone\e[0m"
  elif [ -f "$1" ]; then
    local filepath=$(realpath "$1")
    echo -e "\e[38;2;138;125;110mSending '$filepath' to phone...\e[0m"
    kdeconnect-cli --device "$device_id" --share "$filepath"
    echo -e "\e[38;2;172;130;233m✓ File sent to phone\e[0m"
  else
    kdeconnect-cli --device "$device_id" --share-text "$*"
    echo -e "\e[38;2;172;130;233m✓ Text sent to phone clipboard\e[0m"
  fi
}
# ── rmbg ─────────────────────────────────────────────────────────────
rmbg() {
  if [ -z "$1" ]; then
    echo "Usage: rmbg <image> [fuzz%]"
    echo "       fuzz controls how aggressively white is removed (default: 10%)"
    return 1
  fi

  if [ ! -f "$1" ]; then
    echo -e "\e[38;2;252;70;73m✘ File not found: '$1'\e[0m"
    return 1
  fi

  local input="$1"
  local fuzz="${2:-10%}"
  local filename=$(basename "$input")
  local name="${filename%.*}"
  local output="$(dirname "$input")/${name}_nobg.png"

  echo -e "\e[38;2;138;125;110mRemoving background from '$filename' (fuzz: $fuzz)...\e[0m"

  convert "$input" \
    -fuzz "$fuzz" \
    -transparent white \
    -alpha set \
    "$output"

  echo -e "\e[38;2;172;130;233m✓ Saved to '$output'\e[0m"
}
