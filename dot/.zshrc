# Enabling Portage completions and Gentoo prompt for zsh
autoload -U compinit promptinit
compinit
promptinit; prompt gentoo

# Enabling cache for the completions for zsh
zstyle ':completion::complete:*' use-cache 1
