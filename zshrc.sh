# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
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
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 7

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
# COMPLETION_WAITING_DOTS="true"

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
plugins=(git)

source $ZSH/oh-my-zsh.sh

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

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

alias zshconfig="code ~/.zshrc"
alias ohmyzsh="code ~/.oh-my-zsh"

# homebrew
alias brewcheck="brew update && echo -e '\033[1mbrew:\033[0m' && brew outdated && echo '\033[1mcask:\033[0m' && brew outdated --cask"
alias brewclean="brew cleanup -ns && brew cleanup -s"
alias brewlist="echo -e '\033[1mbrew:\033[0m' && brew list && echo '\033[1mcask:\033[0m' && brew list --cask"
alias brewupg="brew upgrade && brew upgrade --cask && brewclean"
alias brc=brewcheck
alias brl=brewlist
alias brn=brewclean
alias bru=brewupg

# git
alias gitsub='git submodule update --init --recursive'
alias gitprune='git remote prune origin'
alias gittag='git describe --abbrev=0'
alias githead='git rev-parse HEAD'

# general
alias c='clear'
alias cleanDS="find . -type f -name '*.DS_Store' -ls -delete"
alias fetch="git fetch --jobs=8 --all --prune --tags --prune-tags"
alias l='ls -Aho'
alias ll='ls -ho'
alias num='echo $(ls -1 | wc -l)'
alias o='open .'
alias outdated="brc && echo -e '\033[1mPython:\033[0m' && pyout"
alias path='echo -e ${PATH//:/\\n}'
alias reload='source ~/.zshrc'
alias trd="tre -d"
alias tre="tree -C -I 'node_modules|venv|__pycache__'"
alias xdir='open ~/Library/Developer/Xcode/DerivedData'

# move files out of subdirectiories
alias nosubdirs="find . -type f -mindepth 2 -exec mv -i -- {} . \;"

# remove all empty folders recursively
alias delempty="find . -depth -mindepth 1 -type d -empty -exec rmdir {} \;"

# Python
alias pirq="python3 -m pip install -r requirements.txt"
alias piu="python3 -m pip install --upgrade"
alias piup="python3 -m pip install --upgrade pip setuptools wheel"
alias pyfreeze="python3 -m pip freeze > requirements.txt"
alias pyinst="pyenv install --list | egrep \\s+3\."
alias pylist="pyenv versions"
alias pynot="python3 -m pip list --outdated --not-required"
alias pyout="python3 -m pip list --outdated"
alias pyupg="python3 -m pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install --upgrade"

# Print a message with red color
print_red() {
    printf "\e[1;49;31m${1}\e[0m\n"
}

# Print a message with green color
print_green() {
    printf "\e[1;49;32m${1}\e[0m\n"
}

# Print a message with yellow color
print_yellow() {
    printf "\e[1;49;33m${1}\e[0m\n"
}

# Print a message with magenta color
print_magenta() {
    printf "\e[1;49;35m${1}\e[0m\n"
}

print_error() {
    print_red "ERROR: ${1}"
}

print_warn() {
    print_yellow "WARNING: ${1}"
}

# activate Python virtual env
act() {
    # try to get venv name from first argument, otherwise default to 'venv'
    local NAME=${1:-venv}
    if [ -e "$HOME/venv/$NAME/bin/activate" ]; then
        echo "Activating $HOME/venv/$NAME"
        source "$HOME/venv/$NAME/bin/activate"
    elif [ -e "$NAME"/bin/activate ]; then
        echo "Activating $(pwd)/$NAME"
        source "$NAME/bin/activate"
    else
        print_error "Could not find venv '$NAME'"
    fi
}

# Create new Python virtual env
venv() {
    # try to get venv name from first argument, otherwise default to 'venv'
    local NAME=${1:-venv}
    python3 -m venv --clear "$HOME/venv/$NAME"
    source "$HOME/venv/$NAME/bin/activate"
}

brew_install_or_upgrade() {
    if brew ls --versions "$1" >/dev/null; then
        brew upgrade "$1"
    else
        brew install "$1"
    fi
}

bri() {
    brew_install_or_upgrade "$1"
}

# always list dir after cd
#cd() { builtin cd "$@"; ll; }

# cd to current top finder window in shell
cdf() {
    local window_path
    window_path=$(/usr/bin/osascript << EOT
        tell application "Finder"
            try
                set currFolder to (folder of the front window as alias)
                    on error
                set currFolder to (path to desktop folder as alias)
            end try
            POSIX path of currFolder
        end tell
EOT
    )
    echo "cd to \"$window_path\""
    cd "$window_path"
}

# remove Dropbox conflicted copies
conflicted() {
    find ~/Dropbox/ -path "*(*'s conflicted copy [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*" -exec rm -f {} \;
}

# Eject all disk images
eject() {
    osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'
}

# Zip given file
zipf() {
    zip -r "$1".zip "$1"
}
