#
# Multi-word, syntax highlighted history searching
#

source "${0:h}/external/history-search-multi-word.plugin.zsh" || return 1

# Bind up key too, so it triggers like history-substring-search does
# zmodload -F zsh/terminfo +p:terminfo
# bindkey "${terminfo[kcuu1]}" "history-search-multi-word"
# bindkey "${terminfo[kcud1]}" "history-search-multi-word-backwards"
