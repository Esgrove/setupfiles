#!/bin/bash
# WSL Ubuntu Bash profile

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

alias profile="nano ~/.profile"

# git
alias gitconf="git config --global --list | sort"
alias gitsub='git submodule update --init --recursive'
alias gitprune='git remote prune origin'
alias gittag='git describe --abbrev=0'
alias githead='git rev-parse HEAD'

alias gconf=gitconf
alias gsub=gitsub
alias gprune=gitprune
alias gtag=gittag
alias ghead=githead

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

# python
alias pirq="python -m pip install -r requirements.txt"
alias piu="python -m pip install --upgrade"
alias piup="python -m pip install --upgrade pip setuptools wheel"
alias pyfreeze="python -m pip freeze > requirements.txt"
alias pynot="python -m pip list --outdated --not-required"
alias pyout="python -m pip list --outdated"
alias pyupg="python -m pip list --not-required --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install --upgrade"

# Print a message with red color
print_red() {
    printf "\e[1;49;31m%s\e[0m\n" "$1"
}

# Print a message with green color
print_green() {
    printf "\e[1;49;32m%s\e[0m\n" "$1"
}

# Print a message with yellow color
print_yellow() {
    printf "\e[1;49;33m%s\e[0m\n" "$1"
}

# Print a message with magenta color
print_magenta() {
    printf "\e[1;49;35m%s\e[0m\n" "$1"
}

print_error() {
    print_red "ERROR: $1"
}

print_warn() {
    print_yellow "WARNING: $1"
}

# Print an error and exit
print_error_and_exit() {
    print_red "ERROR: $1"
    # use exit code if given as argument, otherwise default to 1
    exit "${2:-1}"
}

# cd to developer dir
cdd() {
    cd "$HOME/Developer" || echo "failed to cd to $HOME/Developer"
    if [ -n "$1" ] && [ -e "$1" ]; then
        cd "$1" || echo "Failed to cd to $1"
    fi
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
    python3 -m venv --clear "$HOME/venv/$NAME"
    source "$HOME/venv/$NAME/Scripts/activate"
}
