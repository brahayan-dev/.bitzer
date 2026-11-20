#!/usr/bin/env zsh

# -----
# Zsh
# -----
export ZSH="$HOME/.oh-my-zsh"
export LANG=en_US.UTF-8

ZSH_THEME="robbyrussell"
HYPHEN_INSENSITIVE="true"

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

DISABLE_AUTO_TITLE="true"
ENABLE_CORRECTION="true"

plugins=(git)
[ -s $ZSH/oh-my-zsh.sh ] && source $ZSH/oh-my-zsh.sh

zsource() {
    source ~/.zshrc
    source ~/.zprofile
    return 0
}

# ------
# Alias
# ------
alias lg='lazygit'
alias deploy='just --justfile "$HOME/Projects/shaun/justfile" deploy'
alias farmer='cd "$HOME/.bitzer/" && ./workstation setup && deploy'

# ---------
# Settings
# ---------
source ~/.zprofile
# NOTE: Editor
export EDITOR=nvim
# NOTE: Repositories
eval "$(just --justfile "$HOME/Projects/shaun/justfile" --quiet generate aliases)"

