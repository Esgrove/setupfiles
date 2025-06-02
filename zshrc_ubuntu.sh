#!/bin/bash
# Ubuntu zsh profile for oh-my-zsh

echo -n "Loading .zshrc"
start_time=$(date +%s%N)

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto        # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 7

zstyle ':completion:*' menu select

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="dd.mm.yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# z: https://github.com/agkozak/zsh-z
plugins=(
    docker
    gh
)

# shellcheck disable=SC1091
source "$ZSH/oh-my-zsh.sh"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='nano'
else
    export EDITOR='nano'
fi

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

alias ohmyzsh="zed ~/.oh-my-zsh"
alias zconf="zed ~/.zshrc"
alias zprof="zed ~/.zprofile"
alias zenv="zed ~/.zshenv"

# git
alias gitconf="git config --global --list | sort"
alias gitfetch="git fetch --jobs=8 --all --prune --tags --prune-tags"
alias githead='git rev-parse HEAD'
alias gitprune='git remote prune origin'
alias gitsub='git submodule update --init --recursive'
alias gittag='git describe --abbrev=0'
alias gitup='gitfetch && git pull --rebase'

alias gconf=gitconf
alias gfetch=gitfetch
alias ghead=githead
alias gmain=git_main
alias gim=git_main
alias giu=gitup
alias gprune=gitprune
alias gsub=gitsub
alias gtag=gittag

# general
alias c='clear'
alias calendar="cal -y || python3 -m calendar"
alias dev="cd ~/Developer && ll"
alias ip='curl -s https://checkip.amazonaws.com'
alias l='ls -Aho'
alias ll='ls -ho'
alias ncalendar="ncal -wy -s FI"
alias num='echo $(ls -1 | wc -l)'
alias o='start .'
alias outdated="echo -e '\033[1mPython:\033[0m' && uv self update && uv tool upgrade --all"
alias path='echo -e ${PATH//:/\\n}'
alias reload='source ~/.zshrc'
alias trd="tre -d"
alias tre="tree -C -I 'node_modules|venv|__pycache__'"

alias less="bat"
alias cat="bat -pp"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# move files out of sub-directiories
alias nosubdirs="find . -mindepth 2 -type f -print -exec mv -i -- {} . \;"

# remove all empty folders recursively
alias delempty="find . -depth -mindepth 1 -type d -empty -print -exec rmdir {} \;"

# Python
alias pirq="python3 -m pip install -r requirements.txt"
alias piu="python3 -m pip install --upgrade"
alias piup="python3 -m pip install --upgrade pip setuptools wheel"
alias pyfreeze="python3 -m pip freeze > requirements.txt"
alias pynot="python3 -m pip list --outdated --not-required"
alias pyout="python3 -m pip list --outdated"

VENV_DIR="$HOME/.venv"

# activate Python virtual env
act() {
    # try to get venv name from first argument, otherwise default to 'venv'
    local NAME=${1:-venv}
    if [ -e "$(pwd)/$NAME"/bin/activate ]; then
        echo "Activating $(pwd)/$NAME"
        source "$NAME/bin/activate"
    elif [ -e "$VENV_DIR/$NAME/bin/activate" ]; then
        echo "Activating $VENV_DIR/$NAME"
        source "$VENV_DIR/$NAME/bin/activate"
    else
        print_error "Could not find venv '$NAME'"
    fi
}

# cd to developer dir
cdd() {
    cd "$HOME/Developer" || echo "failed to cd to $HOME/Developer"
    if [ -n "$1" ] && [ -e "$1" ]; then
        cd "$1" || echo "Failed to cd to $1"
    fi
}

git_main() {
    # Check if the 'main' branch exists in the local repository
    if git show-ref --verify --quiet refs/heads/main; then
        git switch main
    else
        git switch master
    fi
}

# Search history
hist() {
    history | grep "$@"
}

# Create new Python virtual env
venv() {
    # try to get venv name from first argument, otherwise default to 'venv'
    local NAME=${1:-venv}
    mkdir -p "$VENV_DIR"
    echo "Creating venv: $VENV_DIR/$NAME"
    python3 -m venv --clear "$VENV_DIR/$NAME"
    source "$VENV_DIR/$NAME/bin/activate"
}

# Go up one or more directories, up to user home
up() {
    local limit="${1:-1}"
    if [ "$limit" -le 0 ]; then
        limit=1
    fi
    pwd
    for ((i = 1; i <= limit; i++)); do
        if [ "$PWD" = "$HOME" ]; then
            break
        fi
        if ! cd "$PWD"/../; then
            echo "Failed to go up from current directory"
            break
        fi
    done
    pwd
}

# Zip given file
zipf() {
    zip -r "$1".zip "$1"
}

# Calculate the elapsed time in milliseconds
end_time=$(date +%s%N)
elapsed_time_ms=$(( (end_time - start_time) / 1000000 ))
elapsed_time_s=$(awk "BEGIN {printf \"%.3f\", $elapsed_time_ms / 1000}")
echo "    $elapsed_time_s s"
