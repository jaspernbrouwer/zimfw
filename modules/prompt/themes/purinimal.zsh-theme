#
# Purinimal (a prompt theme)
# https://github.com/jaspernbrouwer/purinimal
#
# Combination of these popular themes:
# - Pure (https://github.com/sindresorhus/pure)
# - Minimal (https://github.com/S1cK94/minimal)
#
# Requires the `git-info` zmodule to be included in the .zimrc file.
#

purinimal_preprompt_env() {
  setopt localoptions noshwordsplit

  # Check SSH_CONNECTION and the current state.
  local ssh_connection=${SSH_CONNECTION:-${PROMPT_PURE_SSH_CONNECTION}}

  if [[ -z ${ssh_connection} ]] && (( ${+commands[who]} )); then
    # When changing user on a remote system, the SSH_CONNECTION environment variable can be lost,
    # attempt detection via who.
    local who_out
    who_out=$(who -m 2>/dev/null)
    if (( $? )); then
      # Who am I not supported, fallback to plain who.
      who_out=$(who 2>/dev/null | grep ${TTY#/dev/})
    fi

    # Simplified, only checks partial pattern.
    local reIPv6="(([0-9a-fA-F]+:)|:){2,}[0-9a-fA-F]+"
    # Simplified, allows invalid ranges.
    local reIPv4="([0-9]{1,3}\.){3}[0-9]+"
    # Assume two non-consecutive periods represents a hostname.
    local reHostname="([.][^. ]+){2}"

    # Usually the remote address is surrounded by parenthesis, but not on all systems
    # (e.g. busybox).
    local -H MATCH MBEGIN MEND
    if [[ ${who_out} =~ "\(?(${reIPv4}|${reIPv6}|${reHostname})\)?\$" ]]; then
      ssh_connection=${MATCH}

      # Export variable to allow detection propagation inside shells spawned by this one
      # (e.g. tmux does not always inherit the same tty, which breaks detection).
      export PROMPT_PURE_SSH_CONNECTION=${ssh_connection}
    fi
    unset MATCH MBEGIN MEND
  fi

  # Check if we should display the VIRTUAL_ENV, we use a sufficiently high index of psvar (12)
  # here to avoid collisions with user defined entries.
  # When VIRTUAL_ENV_DISABLE_PROMPT is empty, it was unset by the user and we should take back
  # control.
  psvar[12]=
  if [[ -n ${VIRTUAL_ENV} ]] && [[ -z ${VIRTUAL_ENV_DISABLE_PROMPT} || ${VIRTUAL_ENV_DISABLE_PROMPT} = 12 ]]; then
    psvar[12]="${VIRTUAL_ENV:t}"
    export VIRTUAL_ENV_DISABLE_PROMPT=12
  fi

  # Check if we need to show username, hostname and/or VIRTUAL_ENV.
  local -a preprompt_env

  # Show username if root or logged in through SSH.
  if [[ ${UID} -eq 0 ]] || [[ -n ${ssh_connection} ]]; then
    preprompt_env+=("%(!.%F{red}%n%f.%n)")
  fi

  # Show hostname if logged in through SSH.
  [[ -n ${ssh_connection} ]] && preprompt_env+=("%F{green}%m%f")

  # Show VIRTUAL_ENV if it is activated.
  [[ -n ${psvar[12]} ]] && preprompt_env+=("%F{yellow}%12v%f")

  # Only print when there's something to show.
  [ ${#preprompt_env[@]} -ne 0 ] && print -n "${(j. .)preprompt_env} "
}

purinimal_preprompt_path() {
  # Calculate length of the "env" and "git" preprompt parts.
  local zero='%([BSUbfksu]|([FK]|){*})'
  local preprompt_env_length=${#${(S%%)1//${~zero}/}}
  local preprompt_git_length=${#${(S%%)2//${~zero}/}}

  # Print path, truncate it if needed.
  print -n "%F{blue}%$((COLUMNS-${preprompt_env_length}-3-${preprompt_git_length}))<…<%~%<<%f"
}

purinimal_preprompt_padding() {
  local zero='%([BSUbfksu]|([FK]|){*})'
  local preprompt_env_length=${#${(S%%)1//${~zero}/}}
  local preprompt_path_length=${#${(S%%)2//${~zero}/}}
  local preprompt_git_length=${#${(S%%)3//${~zero}/}}

  # Print padding for between env + path and git
  print -n ${(r:$((COLUMNS-${preprompt_env_length}-${preprompt_path_length}-${preprompt_git_length})):)}
}

purinimal_preprompt_git() {
  # Fetch git-info.
  (( ${+functions[git-info]} )) && git-info

  # Print git-info when inside a git working copy.
  [[ -n ${git_info} ]] && print -n " ${(e)git_info[prompt]}"
}

purinimal_mark_user() {
  # Red when user is privileged.
  print -n "%(!.%F{red}.%f)${PURINIMAL_MARK:-❯}"
}

purinimal_mark_jobs() {
  # Cyan when background processes are running.
  print -n "%(1j.%F{cyan}.%f)${PURINIMAL_MARK:-❯}"
}

purinimal_mark_vimode() {
  # Blue when in vi mode.
  local color

  case ${KEYMAP} in
    main|viins)
      color=%F{blue}
      ;;
    *)
      color=%f
      ;;
  esac

  print -n "${color}${PURINIMAL_MARK:-❯}"
}

purinimal_mark_exitcode() {
  # Green when exit code is 0, red otherwise.
  print -n "%(0?.%F{green}.%F{red})${PURINIMAL_MARK:-❯}"
}

prompt_purinimal_preexec() {
  # Disallow python VIRTUAL_ENV from updating the prompt, set it to 12 if untouched by the user to
  # indicate that we modified it. Here we use magic number 12, same as in psvar.
  export VIRTUAL_ENV_DISABLE_PROMPT=${VIRTUAL_ENV_DISABLE_PROMPT:-12}
}

prompt_purinimal_precmd() {
  setopt localoptions noshwordsplit

  # Build the prepromt parts
  local preprompt_env=$(purinimal_preprompt_env)
  local preprompt_git=$(purinimal_preprompt_git)
  local preprompt_path=$(purinimal_preprompt_path ${preprompt_env} ${preprompt_git})
  local preprompt_padding=$(purinimal_preprompt_padding ${preprompt_env} ${preprompt_path} ${preprompt_git})

  # Remove everything from the prompt until the newline. This removes the preprompt and only the
  # original PROMPT remains.
  local cleaned_ps1=${PROMPT}
  local -H MATCH MBEGIN MEND
  if [[ ${PROMPT} = *${prompt_newline}* ]]; then
    cleaned_ps1=${PROMPT##*${prompt_newline}}
  fi
  unset MATCH MBEGIN MEND

  # Construct the new prompt with a clean preprompt.
  local -ah ps1
  ps1=(
    "${preprompt_env}${preprompt_path}${preprompt_padding}${preprompt_git}"
    ${prompt_newline}
    ${cleaned_ps1}
  )

  PROMPT="${(j..)ps1}"

  # Initial newline, for spaciousness.
  print
}

prompt_purinimal_setup() {
  # Prevent percentage showing up if output doesn't end with a newline.
  export PROMPT_EOL_MARK=""

  # Borrowed from promptinit, sets the prompt options in case pure was not initialized via
  # promptinit.
  prompt_opts=(subst percent)
  setopt noprompt{bang,cr,percent,subst} "prompt${^prompt_opts[@]}"

  # This variable needs to be set, usually set by promptinit.
  if [[ -z ${prompt_newline} ]]; then
    typeset -g prompt_newline=$'\n%{\r%}'
  fi

  # Load modules.
  zmodload zsh/zle
  zmodload zsh/parameter

  autoload -Uz colors && colors
  autoload -Uz add-zsh-hook

  # Initialize hooks.
  add-zsh-hook precmd prompt_purinimal_precmd
  add-zsh-hook preexec prompt_purinimal_preexec

  # Configure git info.
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

  # Display the prompt
  PROMPT="$(purinimal_mark_user)$(purinimal_mark_jobs)$(purinimal_mark_vimode)$(purinimal_mark_exitcode)%f "
  RPROMPT=
}

prompt_purinimal_setup "$@"
