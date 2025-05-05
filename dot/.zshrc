# enabling portage completions, corrections and gentoo prompt for zsh
autoload -U compinit promptinit
compinit
setopt correctall
promptinit; prompt gentoo

# enabling cache for the completions of zsh
zstyle ':completion::complete:*' use-cache 1
