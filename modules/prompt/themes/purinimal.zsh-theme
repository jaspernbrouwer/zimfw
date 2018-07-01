#
# Purinimal theme
# https://github.com/jaspernbrouwer/...
#
# Based on these popular themes
# - Pure (https://github.com/sindresorhus/pure)
# - Minimal (https://github.com/S1cK94/minimal)
#
# Requires the `git-info` zmodule to be included in the .zimrc file
#

pp_user() {
  # Red when user is privileged
  print -n '%(!.%F{red}.%f)❯'
}

pp_jobs() {
  # Cyan when background processes are running
  print -n '%(1j.%F{cyan}.%f)❯'
}

pp_vimode() {
  # Blue when in vi mode
  local color

  case ${KEYMAP} in
    main|viins)
      color=%F{blue}
      ;;
    *)
      color=%f
      ;;
  esac

  print -n "${color}❯"
}

pp_status() {
  # Green when exit code is 0, red otherwise
  print -n '%(0?.%F{green}.%F{red})❯'
}

pp_hostinfo() {
  local -a pp_hostinfo

  # When in a SSH session, include username (red when privileged) and hostname (green)
  [[ -n ${SSH_CONNECTION} ]] && pp_hostinfo=(${pp_hostinfo} "%(!.%F{red}%n%f.%n) %F{green}%m%f")

  # When active, include virtualenv (yellow)
  [[ -n ${psvar[12]} ]] && pp_hostinfo=(${pp_hostinfo} "%F{yellow}%12v%f")

  # Only print when there's something to show
  [ ${#pp_hostinfo[@]} -ne 0 ] && print -n "${(j. .)pp_hostinfo} "
}

pp_git() {
  # Print git-info part when inside a git working copy
  [[ -n ${git_info} ]] && print -n " ${(e)git_info[color]}${(e)git_info[prompt]}"
}

function zle-line-init zle-keymap-select {
  # Reset prompt when the keymap changes
  zle reset-prompt
  zle -R
}

prompt_purinimal_precmd() {
  # Prevent field splitting to be performed on unquoted parameter expansion
  setopt localoptions noshwordsplit

  # Fetch git info
  (( ${+functions[git-info]} )) && git-info

  # Store name of virtualenv in psvar if activated
  psvar[12]=
  [[ -n ${VIRTUAL_ENV} ]] && psvar[12]="${VIRTUAL_ENV:t}"

  # For calculating the lengt of a string without prompt escape sequences
  local zero='%([BSUbfksu]|([FK]|){*})'

  local pp_left pp_left_length
  local pp_padding
  local pp_right pp_right_length

  # Build right part first
  pp_right=$(pp_git)
  pp_right_length=${#${(S%%)pp_right//$~zero/}}

  # Build hostinfo part (left), add space unless empty
  pp_left_hostinfo=$(pp_hostinfo)
  pp_left_hostinfo_length=${#${(S%%)pp_left_hostinfo//$~zero/}}

  # Build path part (left), truncate when needed
  pp_left_path="%$((COLUMNS-${pp_left_hostinfo_length}-3-${pp_right_length}))<…<%~%<<"

  # Combine hostinfo and path parts into the full left part
  pp_left="${pp_left_hostinfo}%F{blue}${pp_left_path}%f"
  pp_left_length=${#${(S%%)pp_left//$~zero/}}

  # Build padding between left and right parts
  pp_padding=${(r:$((COLUMNS-${pp_left_length}-${pp_right_length})):)}

  # Combine all parts into the full line
  local pp_full_line="${pp_left}${pp_padding}${pp_right}"

  # When the prompt contains newlines, we keep everything before the first and after the last newline,
  # leaving us with everything except the preprompt. This is needed because some software prefixes the
  # prompt (e.g. virtualenv).
  local pp_cleaned_ps1=${PROMPT}
  local -H MATCH
  if [[ ${PROMPT} = *$prompt_newline* ]]; then
    pp_cleaned_ps1=${PROMPT%%${prompt_newline}*}${PROMPT##*${prompt_newline}}
  fi

  # Construct the new prompt with a clean preprompt
  local -ah ps1
  ps1=(
    ${prompt_newline}
    ${pp_full_line}
    ${prompt_newline}
    ${pp_cleaned_ps1}
  )

  PROMPT="${(j..)ps1}"
}

prompt_purinimal_setup() {
  # Prevent field splitting to be performed on unquoted parameter expansion
  setopt localoptions noshwordsplit

  # Prevent percentage showing up if output doesn't end with a newline
  export PROMPT_EOL_MARK=''

  # Disallow python virtualenvs from updating the prompt
  export VIRTUAL_ENV_DISABLE_PROMPT=1

  # Borrowed from promptinit, sets the prompt options in case pure was not initialized via promptinit
  prompt_opts=(subst percent)
  setopt noprompt{bang,cr,percent,subst} "prompt${^prompt_opts[@]}"

  # This variable needs to be set, usually set by promptinit.
  if [[ -z ${prompt_newline} ]]; then
    typeset -g prompt_newline=$'\n%{\r%}'
  fi

  # zle -N zle-line-init
  # zle -N zle-keymap-select

  autoload -Uz colors && colors
  autoload -Uz add-zsh-hook

  add-zsh-hook precmd prompt_purinimal_precmd

  # Configure git info
  zstyle ':zim:git-info:action:bisect'               format 'B'
  zstyle ':zim:git-info:action:apply'                format 'A'
  zstyle ':zim:git-info:action:cherry-pick'          format 'C'
  zstyle ':zim:git-info:action:cherry-pick-sequence' format 'C'
  zstyle ':zim:git-info:action:merge'                format 'M'
  zstyle ':zim:git-info:action:rebase'               format 'R'
  zstyle ':zim:git-info:action:rebase-interactive'   format 'R'
  zstyle ':zim:git-info:action:rebase-merge'         format 'R'

  zstyle ':zim:git-info:clean'     format '%F{green}'
  zstyle ':zim:git-info:branch'    format ' %b%%f'
  zstyle ':zim:git-info:commit'    format '%%F{magenta} %c%%f'
  zstyle ':zim:git-info:action'    format ' %%B%%F{red}✖ %s%%f%%b'
  zstyle ':zim:git-info:behind'    format ' %%B%%F{white}↓ %B%%f%%b'
  zstyle ':zim:git-info:ahead'     format ' %%B%%F{white}↑ %A%%f%%b'
  zstyle ':zim:git-info:indexed'   format ' %%F{green}● %i%%f'
  zstyle ':zim:git-info:unindexed' format ' %%F{16}✚ %I%%f'
  zstyle ':zim:git-info:untracked' format ' %%F{yellow}… %u%%f'
  zstyle ':zim:git-info:stashed'   format ' %%F{blue}⚑ %S%%f'

  zstyle ':zim:git-info:keys' format 'prompt' '%C%b%c%s%B%A%i%I%u%S'

  PROMPT="$(pp_user)$(pp_jobs)$(pp_vimode)$(pp_status)%f "
  unset RPROMPT
}

prompt_purinimal_setup "$@"
