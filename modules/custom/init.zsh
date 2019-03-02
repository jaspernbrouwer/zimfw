#
# Custom aliases/settings
#

# any custom stuff should go here.
# ensure that 'custom' exists in the zmodules array in your .zimrc


# Add Composer (PHP) and yarn (JS) binaries to the path
export PATH=${PATH}:/home/jasper/.config/composer/vendor/bin
export PATH=${PATH}:/home/jasper/.config/yarn/global/node_modules/.bin

# Don't share history between terminals
unsetopt SHARE_HISTORY

# Colored output
alias ip="${aliases[ip]:-ip} -c"
alias ls="${aliases[ls]:-ls} -F"
alias la="${aliases[l]:-l}"

# Case-insensative grep by default
alias grep="${aliases[grep]:-grep} -i"

# Expand aliases after sudo
alias sudo="sudo "
alias _="sudo "

# Sort system packages by name
#alias yay="yay --sortby=name"

# Base16 shell
local BASE16_SHELL="${ZDOTDIR:-$HOME}/.config/base16-shell/"
[ -n "$PS1" ] && [ -s "$BASE16_SHELL/profile_helper.sh" ] && eval "$("$BASE16_SHELL/profile_helper.sh")"
