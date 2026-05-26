# ── Prompt Colors ────────────────────────────────────────────────────
RESET='\[\e[0m\]'
BG_PROMPT='\[\e[48;2;40;30;60m\]'      # dark purple background
BG_DARK='\[\e[48;2;17;16;20m\]'        # #111014
FG_PURPLE='\[\e[38;2;172;130;233m\]'   # #AC82E9
FG_TEXT='\[\e[38;2;216;202;184m\]'     # #d8cab8
FG_MUTED='\[\e[38;2;138;125;110m\]'    # #8a7d6e
FG_ERROR='\[\e[38;2;252;70;73m\]'      # #fc4649

# ── Prompt ───────────────────────────────────────────────────────────
# Shows exit code of last command if it failed
_prompt_exit_code() {
  local code=$?
  if [ $code -ne 0 ]; then
    echo -e "\e[38;2;252;70;73m✘ $code\e[0m "
  fi
}

PS1='$(_prompt_exit_code)'"${BG_PROMPT}${FG_PURPLE} \u${FG_MUTED}@${FG_TEXT}\h ${FG_MUTED}\w \[$(tput el)\]${RESET}
${FG_PURPLE}❯${RESET} "
