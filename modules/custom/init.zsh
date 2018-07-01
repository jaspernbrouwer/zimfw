#
# Custom aliases/settings
#

# any custom stuff should go here.
# ensure that 'custom' exists in the zmodules array in your .zimrc


# Don't share history between terminals
unsetopt SHARE_HISTORY

# Colored output
alias ip="${aliases[ip]:-ip} -c"
alias ls="${aliases[ls]:-ls} -F"
alias la="${aliases[l]:-l}"

# Expand aliases after sudo
alias sudo="sudo "
alias _="sudo "

# Base16 shell
local BASE16_SHELL="${ZDOTDIR:-$HOME}/.config/base16-shell/"
[ -n "$PS1" ] && [ -s "$BASE16_SHELL/profile_helper.sh" ] && eval "$("$BASE16_SHELL/profile_helper.sh")"
