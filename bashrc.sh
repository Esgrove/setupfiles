#!/bin/bash
# Windows Bash profile

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export TERM="xterm-256color"

alias bprofile="code ~/.profile"

# Add alias for python3 since Windows defaults to just 'python'
alias python3=python

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

# Run ssh-agent automatically when you open bash.
# https://docs.github.com/en/authentication/connecting-to-github-with-ssh/working-with-ssh-key-passphrases?platform=windows
env=~/.ssh/agent.env

agent_load_env() {
    test -f "$env" && . "$env" >| /dev/null
}

agent_start() {
    (
        umask 077
        ssh-agent >| "$env"
    )
    . "$env" >| /dev/null
}

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2=agent not running
agent_run_state=$(
    ssh-add -l >| /dev/null 2>&1
    echo $?
)

if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
    agent_start
    ssh-add
elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
    ssh-add
fi

unset env

export PATH="$PATH:/c/ProgramData/chocolatey/bin/"
