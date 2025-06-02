#!/bin/bash
# Windows Bash profile

echo -n "Loading .bashrc"
start_time=$(date +%s%N)

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export TERM="xterm-256color"

# Append to the history file, don't overwrite it
shopt -s histappend

# After each command, save and reload the history
PROMPT_COMMAND='history -a; history -c; history -r'

# Set the maximum number of lines contained in the history file
HISTFILESIZE=10000

# Set the maximum number of commands to remember in the command history
HISTSIZE=1000

VENV_DIR="$HOME/.venv"

alias bconf="code ~/.bashrc"
alias bprof="code ~/.profile"
alias benv="code ~/.bash_profile"

# Add alias for python3 since Windows defaults to just 'python'
alias python3=python

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
alias gim=git_main
alias giu=gitup
alias gprune=gitprune
alias gsub=gitsub
alias gtag=gittag

# general
alias c='clear'
alias calendar="python -m calendar"
alias fetch="git fetch --jobs=8 --all --prune --tags --prune-tags"
alias l='ls -Aho'
alias ll='ls -ho'
alias num='echo $(ls -1 | wc -l)'
alias o='start .'
alias path='echo -e ${PATH//:/\\n}'
alias reload='source ~/.profile'

# yt-dlp aka youtube-dl
alias ytd="yt-dlp --extract-audio --audio-format wav"

# python
alias pirq="python -m pip install -r requirements.txt"
alias piu="python -m pip install --upgrade"
alias piup="python -m pip install --upgrade pip setuptools wheel"
alias pyfreeze="python -m pip freeze > requirements.txt"
alias pynot="python -m pip list --outdated --not-required"
alias pyout="python -m pip list --outdated"
alias pyupg="python -m pip list --not-required --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install --upgrade"

# cd to code dir
cdc() {
    cd "/d/Dropbox/CODE" || echo "failed to cd to /d/Dropbox/CODE"
    if [ -n "$1" ] && [ -e "$1" ]; then
        cd "$1" || echo "Failed to cd to $1"
    fi
}

# cd to developer dir
cdd() {
    cd "$HOME/Developer" || echo "failed to cd to $HOME/Developer"
    if [ -n "$1" ] && [ -e "$1" ]; then
        cd "$1" || echo "Failed to cd to $1"
    fi
}

# cd to Dropbox dir
cdx() {
    cd "/d/Dropbox" || echo "failed to cd to /d/Dropbox"
    if [ -n "$1" ] && [ -e "$1" ]; then
        cd "$1" || echo "Failed to cd to $1"
    fi
}

aiffrename() {
    find . -type f -name "*.aiff" -print -exec bash -c 'mv "$0" "${0%.aiff}.aif"' {} \;
}

# Search history
hist() {
    history | grep "$1"
}

# Activate Python virtual env
act() {
    # try to get venv name from first argument, otherwise default to 'venv'
    local NAME=${1:-venv}
    if [ -e "$HOME/venv/$NAME/Scripts/activate" ]; then
        echo "Activating $HOME/venv/$NAME"
        source "$HOME/venv/$NAME/Scripts/activate"
    elif [ -e "$NAME"/Scripts/activate ]; then
        echo "Activating $(pwd)/$NAME"
        source "$NAME/Scripts/activate"
    else
        print_error "Could not find venv '$NAME'"
    fi
}

# Create new Python virtual env
venv() {
    # try to get venv name from first argument, otherwise default to 'venv'
    local NAME=${1:-venv}
    mkdir -p "$VENV_DIR"
    echo "Creating venv to $VENV_DIR/$NAME"
    python -m venv --clear "$VENV_DIR/$NAME"
    source "$VENV_DIR/$NAME/Scripts/activate"
}

# Calculate the elapsed time in milliseconds
end_time=$(date +%s%N)
elapsed_time_ms=$(((end_time - start_time) / 1000000))
elapsed_time_s=$(awk "BEGIN {printf \"%.3f\", $elapsed_time_ms / 1000}")
echo "       $elapsed_time_s s"
