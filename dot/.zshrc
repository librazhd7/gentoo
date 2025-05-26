#!/bin/zsh

# enabling portage completions and gentoo prompt for zsh
autoload -U compinit promptinit
compinit
promptinit; prompt gentoo

# enabling cache for the completions for zsh
zstyle ':completion::complete:*' use-cache 1
