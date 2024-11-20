#!/bin/bash
set -eo pipefail

# Setup new personal Mac

USAGE="Usage: $0 [OPTIONS]

Setup new personal Mac.
This script is safe to run multiple times.

OPTIONS: All options are optional
    -h | --help
        Display these instructions.

    -b | --skip-brew
        Skip brew installs.

    -s | --skip-settings
        Skip writing macOS settings.

    -v | --verbose
        Display commands being executed.
"

SKIP_BREW=false
SKIP_SETTINGS=false
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            echo "$USAGE"
            exit 0
            ;;
        -b | --skip-brew)
            SKIP_BREW=true
            ;;
        -s | --skip-settings)
            SKIP_SETTINGS=true
            ;;
        -v | --verbose)
            set -x
            ;;
    esac
    shift
done

GIT_NAME="Esgrove"
GIT_EMAIL="esgrove@outlook.com"
SSH_KEY="$HOME/.ssh/id_ed25519"
GPG_KEY="$HOME/esgrove-gpg-private-key.asc"
GPG_KEY_ID="9A95370F12C4825C"
GPG_KEY_FINGERPRINT="2696E274A2E739B7A5B6FB589A95370F12C4825C"
# Always loaded, regardless of whether the shell is a login shell, interactive shell, or non-interactive shell.
SHELL_PROFILE="$HOME/.zshenv"
# Computer ID to use in GitHub
# For example: Esgrove MacBookPro18,1 2022-12-30
COMPUTER_ID="$GIT_NAME $(sysctl hw.model | awk '{print $2}') $(date +%Y-%m-%d)"

# Set Apple Silicon variable
if [ -z "$ARM" ]; then
    # This method works regardless if this script is run in a Rosetta (x86) terminal process
    CPU_NAME="$(/usr/sbin/sysctl -n machdep.cpu.brand_string)"
    if [[ $CPU_NAME =~ "Apple" ]]; then
        ARM=true
        PROCESSOR=$(echo "$CPU_NAME" | awk '{print $2}')
    else
        ARM=false
        PROCESSOR="Intel"
    fi
fi

# Function to check if on Apple Silicon or not
is_apple_silicon() {
    if [ "$ARM" = true ]; then
        return
    elif [ -z "$ARM" ]; then
        print_error_and_exit "Architecture is not set"
    fi

    false
}

print_bold() {
    printf "\e[1m%s\e[0m\n" "$1"
}

print_green() {
    printf "\e[1;49;32m%s\e[0m\n" "$1"
}

print_magenta() {
    printf "\e[1;49;35m%s\e[0m\n" "$1"
}

print_red() {
    printf "\e[1;49;31m%s\e[0m\n" "$1"
}

print_yellow() {
    printf "\e[1;49;33m%s\e[0m\n" "$1"
}

# Print an error and exit
print_error_and_exit() {
    print_red "ERROR: $1"
    # use exit code if given as argument, otherwise default to 1
    exit "${2:-1}"
}

press_enter_to_continue() {
    read -r -p "Press [Enter] to continue..."
}

brew_install_or_upgrade() {
    local name="$1"
    if brew ls --versions "$name" > /dev/null; then
        if ! brew upgrade --formula "$name"; then
            print_red "Failed to upgrade $name, continuing..."
        fi
    else
        print_magenta "Installing $name"
        brew info "$name"
        if ! brew install --formula "$name"; then
            print_red "Failed to install $name, continuing..."
        fi
    fi
}

brew_cask_install_or_upgrade() {
    local name="$1"
    if brew ls --cask --versions "$name" > /dev/null; then
        if ! brew upgrade --cask "$name"; then
            print_red "Failed to upgrade cask $name, continuing..."
        fi
    else
        print_magenta "Installing $name"
        brew info "$name"
        if ! brew install --cask "$name"; then
            print_red "Failed to install cask $name, continuing..."
        fi
    fi
}

git_clone() {
    local repo_url="$1"
    local repo_name
    repo_name=$(basename -s .git "$repo_url")

    if [ -d "$repo_name" ]; then
        print_yellow "Repository '$repo_name' already exists, skipping clone..."
    else
        print_magenta "Cloning $repo_name"
        git clone "$repo_url"
    fi
}

set_macos_settings() {
    # macOS settings mostly from:
    # https://github.com/mathiasbynens/dotfiles/blob/66ba9b3cc0ca1b29f04b8e39f84e5b034fdb24b6/.macos

    print_magenta "Modifying macOS settings..."
    print_yellow "NOTE: a restart is required for the settings to take effect!"

    # Ask for the administrator password upfront
    sudo -v

    # Keep-alive: update existing sudo time stamp until the script has finished
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2> /dev/null &

    # Remove unneeded apps
    sudo rm -rf /Applications/GarageBand.app
    sudo rm -rf /Applications/iMovie.app
    sudo rm -rf /Applications/Keynote.app
    sudo rm -rf /Applications/Numbers.app
    sudo rm -rf /Applications/Pages.app

    FIRST_NAME=$(echo "$GIT_NAME" | cut -d' ' -f1)
    COMPUTER_NAME="$FIRST_NAME $PROCESSOR"
    HOST_NAME="$(echo -n "$COMPUTER_NAME" | tr '[:upper:]' '[:lower:]' | tr '[:space:]' '-')"

    echo "Setting computer name: '$COMPUTER_NAME'"
    sudo scutil --set ComputerName "$COMPUTER_NAME"

    echo "Setting host name:     '$HOST_NAME'"
    sudo scutil --set HostName "$HOST_NAME"
    sudo scutil --set LocalHostName "$HOST_NAME"

    # Show hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true

    # Disable natural scroll direction
    defaults write -g com.apple.swipescrolldirection -bool false

    # Expand save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

    # Expand print panel by default
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    # Disable the "Are you sure you want to open this application?" dialog
    defaults write com.apple.LaunchServices LSQuarantine -bool false

    # Disable automatic capitalization as it's annoying when typing code
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

    # Disable smart dashes as they're annoying when typing code
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Disable automatic period substitution as it's annoying when typing code
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

    # Disable smart quotes as they're annoying when typing code
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Save screenshots to Pictures
    defaults write com.apple.screencapture location -string "$HOME/Pictures"

    # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
    defaults write com.apple.screencapture type -string "png"

    # Disable shadow in screenshots
    defaults write com.apple.screencapture disable-shadow -bool true

    # Finder: show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Display full POSIX path as Finder window title
    #defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

    # Keep folders on top when sorting by name
    defaults write com.apple.finder _FXSortFoldersFirst -bool true

    # When performing a search, search the current folder by default
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Avoid creating .DS_Store files on network or USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    # Automatically open a new Finder window when a volume is mounted
    defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
    defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
    defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Set Finder to display home directory by default
    defaults write com.apple.finder NewWindowTarget -string "PfHm"

    # Set Finder to not show "Recent Tags" in the sidebar
    defaults write com.apple.finder ShowRecentTags -bool false

    # Expand the following File Info panes:
    # "General", "Open with", and "Sharing & Permissions"
    defaults write com.apple.finder FXInfoPanesExpanded -dict \
        General -bool true \
        OpenWith -bool true \
        Privileges -bool true

    # Minimize windows into their application's icon
    defaults write com.apple.dock minimize-to-application -bool true

    # Show indicator lights for open applications in the Dock
    defaults write com.apple.dock show-process-indicators -bool true

    # Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool true

    # Don't show recent applications in Dock
    defaults write com.apple.dock show-recents -bool false

    # Disable Time Machine
    sudo tmutil disable

    # Disable Sound Effects on Boot
    # One of these should work :(
    sudo nvram SystemAudioVolume=" "
    #sudo nvram SystemAudioVolume=%80
    #sudo nvram SystemAudioVolume=%01
    #sudo nvram SystemAudioVolume=%00
    #sudo nvram SystemAudioVolume=0
}

brew_install() {
    print_magenta "Installing tools and libraries..."
    # Libraries
    brew_install_or_upgrade ffmpeg             # https://github.com/FFmpeg/FFmpeg
    brew_install_or_upgrade flac               # https://github.com/xiph/flac
    brew_install_or_upgrade fmt                # https://github.com/fmtlib/fmt
    brew_install_or_upgrade git                # https://github.com/git/git
    brew_install_or_upgrade openssl@3
    brew_install_or_upgrade wget

    # Programming languages and compilers
    brew_install_or_upgrade python             # https://github.com/python/cpython
    brew_install_or_upgrade rustup             # https://github.com/rust-lang/rustup

    # CLI tools etc
    brew_install_or_upgrade aria2              # https://github.com/aria2/aria2
    brew_install_or_upgrade bat                # https://github.com/sharkdp/bat
    brew_install_or_upgrade cargo-nextest      # https://github.com/nextest-rs/nextest
    brew_install_or_upgrade ccache             # https://github.com/ccache/ccache
    brew_install_or_upgrade clang-format       # https://github.com/llvm/llvm-project
    brew_install_or_upgrade coreutils          # https://github.com/coreutils/coreutils
    brew_install_or_upgrade erdtree            # https://github.com/solidiquis/erdtree
    brew_install_or_upgrade fd                 # https://github.com/sharkdp/fd
    brew_install_or_upgrade fzf                # https://github.com/junegunn/fzf
    brew_install_or_upgrade gh                 # https://github.com/cli/cli
    brew_install_or_upgrade ghostscript        # https://www.ghostscript.com
    brew_install_or_upgrade gnupg              # https://github.com/gpg/gnupg
    brew_install_or_upgrade gti                # https://github.com/rwos/gti
    brew_install_or_upgrade htop               # https://github.com/htop-dev/htop
    brew_install_or_upgrade imagemagick        # https://github.com/ImageMagick/ImageMagick
    brew_install_or_upgrade jq                 # https://github.com/jqlang/jq
    brew_install_or_upgrade pinentry-mac       # https://github.com/GPGTools/pinentry-mac
    brew_install_or_upgrade pre-commit         # https://github.com/pre-commit/pre-commit
    brew_install_or_upgrade ripgrep            # https://github.com/BurntSushi/ripgrep
    brew_install_or_upgrade sccache            # https://github.com/mozilla/sccache
    brew_install_or_upgrade shellcheck         # https://github.com/koalaman/shellcheck
    brew_install_or_upgrade shfmt              # https://github.com/mvdan/sh
    brew_install_or_upgrade taglib             # https://github.com/taglib/taglib
    brew_install_or_upgrade tex-fmt            # https://github.com/WGUNDERWOOD/tex-fmt
    brew_install_or_upgrade tree
    brew_install_or_upgrade typst              # https://github.com/typst/typst
    brew_install_or_upgrade yarn               # https://github.com/yarnpkg/yarn
    brew_install_or_upgrade yazi               # https://github.com/sxyazi/yazi

    print_magenta "Installing apps..."
    #brew_cask_install_or_upgrade affinity-designer
    #brew_cask_install_or_upgrade affinity-photo
    #brew_cask_install_or_upgrade affinity-publisher
    brew_cask_install_or_upgrade chatgpt
    brew_cask_install_or_upgrade dropbox
    brew_cask_install_or_upgrade firefox
    brew_cask_install_or_upgrade google-chrome
    brew_cask_install_or_upgrade iterm2
    brew_cask_install_or_upgrade libreoffice
    brew_cask_install_or_upgrade logi-options+
    brew_cask_install_or_upgrade spotify
    brew_cask_install_or_upgrade sublime-merge
    brew_cask_install_or_upgrade suspicious-package
    brew_cask_install_or_upgrade tg-pro
    brew_cask_install_or_upgrade visual-studio-code
    brew_cask_install_or_upgrade vlc
    brew_cask_install_or_upgrade warp
    brew_cask_install_or_upgrade zed

    # Audio
    brew_cask_install_or_upgrade ableton-live-suite
    brew_cask_install_or_upgrade ilok-license-manager
    brew_cask_install_or_upgrade izotope-product-portal
    brew_cask_install_or_upgrade native-access
    brew_cask_install_or_upgrade reaper
    brew_cask_install_or_upgrade rekordbox

    print_magenta "Installing fonts..."
    brew_cask_install_or_upgrade font-commit-mono
    brew_cask_install_or_upgrade font-jetbrains-mono
    brew_cask_install_or_upgrade font-jetbrains-mono-nerd-font
    brew_cask_install_or_upgrade font-roboto
    brew_cask_install_or_upgrade font-roboto-mono

    print_magenta "Finish brewing..."
    brew cleanup -ns
    brew cleanup -s
}

print_green "Setting up a Mac for $GIT_NAME <$GIT_EMAIL>"

# Print hardware info
system_profiler SPHardwareDataType | sed '1,4d' | awk '{$1=$1; print}'
system_profiler SPSoftwareDataType | sed '1,4d' | awk '{$1=$1; print}'

echo "Platform: $(uname -mp), CPU: $CPU_NAME"
if is_apple_silicon; then
    if [ "$(uname -m)" = "x86_64" ]; then
        print_red "Running with Rosetta on Apple Silicon"
    else
        echo "Running on Apple Silicon"
    fi
else
    echo "Running on Intel x86"
fi

press_enter_to_continue

if [ "$SKIP_SETTINGS" = false ]; then
    set_macos_settings
else
    print_yellow "Skipping macOS settings..."
fi

touch "$SHELL_PROFILE"

if ! grep -q "^autoload -U +X bashcompinit && bashcompinit" "$SHELL_PROFILE"; then
    echo "Adding 'autoload -U +X bashcompinit && bashcompinit' to $SHELL_PROFILE"
    echo "autoload -U +X bashcompinit && bashcompinit" >> "$SHELL_PROFILE"
fi

if ! grep -q "^autoload -U +X compinit && compinit" "$SHELL_PROFILE"; then
    echo "Adding 'autoload -U +X compinit && compinit' to $SHELL_PROFILE"
    echo "autoload -U +X compinit && compinit" >> "$SHELL_PROFILE"
fi

# Create developer dir
mkdir -p "$HOME/Developer"

# Create config dir
mkdir -p "$HOME/.config"

# Install homebrew if needed
if [ -z "$(command -v brew)" ]; then
    print_magenta "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    print_magenta "Brew already installed, updating..."
    brew update
fi

# Add homebrew to PATH, this is not done on M1 Macs automatically
if is_apple_silicon; then
    echo "Loading brew paths..."
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' < "$SHELL_PROFILE"; then
        echo "Adding homebrew to PATH for Apple Silicon..."
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$SHELL_PROFILE"
    fi
    # Check if Rosetta 2 process is found
    if /usr/bin/pgrep oahd > /dev/null; then
        echo "Rosetta2 already installed, skipping..."
    else
        print_magenta "Installing Rosetta2..."
        sudo softwareupdate --install-rosetta --agree-to-license
    fi
fi

# UTF8
if ! grep -q "export LC_ALL=en_US.UTF-8" < "$SHELL_PROFILE"; then
    echo "Adding 'export LC_ALL=en_US.UTF-8' to $SHELL_PROFILE"
    echo "export LC_ALL=en_US.UTF-8" >> "$SHELL_PROFILE"
fi
if ! grep -q "export LANG=en_US.UTF-8" < "$SHELL_PROFILE"; then
    echo "Adding 'export LANG=en_US.UTF-8' to $SHELL_PROFILE"
    echo "export LANG=en_US.UTF-8" >> "$SHELL_PROFILE"
fi

if [ "$SKIP_BREW" = false ]; then
    brew_install
else
    print_yellow "Skipping brew package installs..."
fi

if [ -z "$(command -v cargo)" ]; then
    print_magenta "Install Rust..."
    rustup-init -y
    source "$HOME/.cargo/env"
    "$HOME/.cargo/bin/rustc" --version
fi
"$HOME/.cargo/bin/rustup" update

if [ -z "$(command -v uv)" ]; then
    print_magenta "Install uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.local/bin/env"
fi

print_magenta "Installing Python packages..."
"$(brew --prefix)/bin/python3" --version
echo "$(uv --version) from $(which uv)"

uv tool install poetry
uv tool install pygments
uv tool install pytest
uv tool install ruff
uv tool install yt-dlp

# shellcheck disable=SC1090
source "$SHELL_PROFILE"

echo "Creating global gitignore..."
echo "__pycache__/
.DS_Store
.idea/
.vscode/
*_i.c
*_p.c
*.aps
*.bak
*.cache
*.dll
*.exe
*.ilk
*.lib
*.log
*.manifest
*.ncb
*.obj
*.pch
*.py[cod]
*.sbr
*.spec
*.suo
*.tlb
*.tlh
*.user
*.vspscc
Thumbs.db" > ~/.gitignore

print_magenta "Setting up git..."
git --version
git-lfs --version
git lfs install --system

git config --global advice.detachedHead false
git config --global core.autocrlf input
git config --global core.editor nano
git config --global core.excludesfile ~/.gitignore
git config --global core.pager 'less -+-R -FRX --mouse'
git config --global credential.helper osxkeychain
git config --global fetch.parallel 0
git config --global fetch.prune true
git config --global fetch.prunetags true
git config --global init.defaultBranch main
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"

print_magenta "git config:"
git config --global --list

print_magenta "Setup GnuPG..."
mkdir -p "$HOME/.gnupg"
# pinentry allows storing gpg key passwords to Apple keychain so you don't have to type it everytime
echo "pinentry-program $(brew --prefix)/bin/pinentry-mac" > "$HOME/.gnupg/gpg-agent.conf"
# Update permissions
chown -R "$(whoami)" ~/.gnupg/
chmod 600 ~/.gnupg/*
chmod 700 ~/.gnupg

if [ -e "$SSH_KEY" ]; then
    print_yellow "SSH key $SSH_KEY already exists, skipping key creation..."
else
    print_magenta "Creating SSH key..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY"
    eval "$(ssh-agent -s)"
    ssh-add --apple-use-keychain "$SSH_KEY"
    echo "Setting SSH config..."
    echo "
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $SSH_KEY" >> ~/.ssh/config
    cat ~/.ssh/config
fi

print_magenta "Adding SSH key to GitHub..."
if [ ! -e "$SSH_KEY.pub" ]; then
    print_error_and_exit "Public key not found: $SSH_KEY.pub"
fi
# use GitHub CLI if available
if [ -n "$(command -v gh)" ]; then
    if ! gh auth status --active; then
        echo "Authorizing GitHub CLI..."
        gh auth login --web --hostname github.com --git-protocol https --scopes admin:public_key,admin:gpg_key,admin:ssh_signing_key
    fi
    ssh_public_key="$(awk '{print $2}' ~/.ssh/id_ed25519.pub)"
    if ! gh ssh-key list | grep -q "$ssh_public_key"; then
        echo "Adding SSH key with name: $COMPUTER_ID"
        gh ssh-key add "$SSH_KEY.pub" --title "$COMPUTER_ID"
    else
        print_yellow "SSH key already added to GitHub, skipping..."
    fi
else
    print_yellow "Opening github.com/settings/keys, add the new SSH key to your profile there"
    echo "It has been copied to the clipboard so you can just paste directly ;)"
    echo "Computer ID: $COMPUTER_ID"
    pbcopy < "$SSH_KEY.pub"
    press_enter_to_continue
    open https://github.com/settings/keys
fi

# GPG key
if [ -e "$GPG_KEY" ]; then
    print_green "Found GPG key $GPG_KEY"
    if ! gpg --list-keys "$GPG_KEY_FINGERPRINT"; then
        echo "Importing key..."
        gpg --import "$GPG_KEY"
        # Verify the key matches the expected ID
        if gpg --list-keys "$GPG_KEY_FINGERPRINT"; then
            print_green "GPG key matches the key ID"
        else
            print_red "Imported GPG key does not match the expected key ID: $GPG_KEY_FINGERPRINT"
            exit 1
        fi
    else
        print_yellow "GPG already imported, skipping..."
    fi

    git config --global user.signingkey "$GPG_KEY_FINGERPRINT"
    git config --global commit.gpgsign true

    if [ -n "$(command -v gh)" ]; then
        if ! gh auth status --active; then
            echo "Authorizing GitHub CLI..."
            gh auth login --web --hostname github.com --git-protocol https --scopes admin:public_key,admin:gpg_key,admin:ssh_signing_key
        fi
        if ! gh gpg-key list | grep -q "$GPG_KEY_ID"; then
            echo "Adding GPG key to GitHub"
            gpg --armor --export "$GPG_KEY_FINGERPRINT" | gh gpg-key add -
        else
            print_yellow "GPG key already added to GitHub, skipping..."
        fi
    fi
else
    # https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key
    print_yellow "Setup GPG key for git manually:"
    echo "Create new key:
        gpg --quick-gen-key '$GIT_NAME <$GIT_EMAIL>'
    Get ID:
        gpg --list-secret-keys
    Use ID to export:
        gpg --armor --export <ID> | pbcopy

    Backup existing key:
        gpg --export-secret-keys <ID> > $GPG_KEY
    Restore key:
        gpg --import $GPG_KEY
    Get ID:
        gpg --list-secret-keys

    Use in git:
        git config --global user.signingkey <ID>
        git config --global commit.gpgsign true"

    gpg --quick-gen-key "$GIT_NAME <$GIT_EMAIL>"
    gpg --list-secret-keys
fi

print_magenta "Cloning repositories..."
cd "$HOME/Developer"
echo "Cloning to $(pwd)"

if ! grep -q "github.com" ~/.ssh/known_hosts; then
    echo "Adding GitHub to known_hosts..."
    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
fi

# Note to self: get full list of repos using
# > gh repo list --json url | jq -r '.[].url'
# get ssh clone urls with:
# > for file in $(gh repo list --json nameWithOwner --jq '.[].nameWithOwner'); do echo \"git@github.com:$file\"; done
git_clone "git@github.com:Esgrove/bandcamp-dl"
git_clone "git@github.com:Esgrove/cli-tools"
git_clone "git@github.com:Esgrove/fdo-dj-opas"
git_clone "git@github.com:Esgrove/fdo-randomizer"
git_clone "git@github.com:Esgrove/playlist-formatter"
git_clone "git@github.com:Esgrove/recordpool-dl"
git_clone "git@github.com:Esgrove/track-rename"

if [ ! -e "$HOME/.oh-my-zsh" ]; then
    print_magenta "Install oh-my-zsh:"
    # https://github.com/ohmyzsh/ohmyzsh
    curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
fi

if [ -e zshrc.sh ]; then
    print_magenta "Copying .zshrc..."
    cp zshrc.sh ~/.zshrc
fi

mkdir "$HOME/.oh-my-zsh/custom/plugins/poetry"
"$HOME/.local/bin/poetry" completions zsh > "$HOME/.oh-my-zsh/custom/plugins/poetry/_poetry"

mkdir "$HOME/.oh-my-zsh/custom/plugins/vault"
"$HOME/.cargo/bin/vault" completion zsh > "$HOME/.oh-my-zsh/custom/plugins/vault/_vault"

# Precompile the completion cache
compinit -C

print_green "Installation done!"

print_magenta "Next steps:"
print_magenta "Use brew zsh:"
print_yellow "sudo chsh -s $(brew --prefix)/bin/zsh"

print_magenta "Restart"
print_yellow "sudo shutdown -r now"
