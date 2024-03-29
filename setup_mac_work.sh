#!/bin/bash
set -eo pipefail

# Setup new work Mac

GIT_NAME="Akseli Lukkarila"
GIT_EMAIL="akseli.lukkarila@nitor.com"
SSH_KEY="$HOME/.ssh/id_ed25519"
GPG_KEY="$HOME/nitor-gpg-private-key.asc"
GPG_KEY_ID="4265756857739FFEB20E3256BADFF60407D07F63"
SHELL_PROFILE="$HOME/.zprofile"
# Computer ID to use in GitHub
# For example: Nitor MacBookPro18,1 2022-12-30
COMPUTER_ID="Nitor $(sysctl hw.model | awk '{print $2}') $(date +%Y-%m-%d)"

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
    if brew ls --versions "$1" > /dev/null; then
        brew upgrade "$1"
    else
        print_magenta "Installing $1"
        brew install "$1"
    fi
}

brew_cask_install_or_upgrade() {
    if brew ls --versions "$1" > /dev/null; then
        brew upgrade --cask "$1"
    else
        print_magenta "Installing $1"
        brew install --cask "$1"
    fi
}

# Set Apple Silicon variable
if [ -z "$ARM" ]; then
    # This method works regardless if this script is run in a Rosetta (x86) terminal process
    CPU_NAME="$(/usr/sbin/sysctl -n machdep.cpu.brand_string)"
    if [[ $CPU_NAME =~ "Apple" ]]; then
        ARM=true
    else
        ARM=false
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

print_green "Setting up a Mac for $GIT_NAME <$GIT_EMAIL>"

# Print hardware info
system_profiler SPHardwareDataType | sed '1,4d' | awk '{$1=$1; print}'

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

# macOS settings mostly from:
# https://github.com/mathiasbynens/dotfiles/blob/66ba9b3cc0ca1b29f04b8e39f84e5b034fdb24b6/.macos

print_magenta "Modifying macOS settings..."
print_yellow "NOTE: a restart is required for the settings to take effect!"

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
touch "$SHELL_PROFILE"
if ! grep -q "export LC_ALL=en_US.UTF-8" < "$SHELL_PROFILE"; then
    echo "Adding 'export LC_ALL=en_US.UTF-8' to $SHELL_PROFILE"
    echo "export LC_ALL=en_US.UTF-8" >> "$SHELL_PROFILE"
fi
if ! grep -q "export LANG=en_US.UTF-8" < "$SHELL_PROFILE"; then
    echo "Adding 'export LANG=en_US.UTF-8' to $SHELL_PROFILE"
    echo "export LANG=en_US.UTF-8" >> "$SHELL_PROFILE"
fi

# Create developer dir
mkdir -p "$HOME/Developer"

# Create AWS CLI dir
mkdir -p "$HOME/.aws"

print_magenta "Installing tools and libraries..."
brew tap hashicorp/tap
brew_install_or_upgrade aria2
brew_install_or_upgrade awscli
brew_install_or_upgrade azure-cli
brew_install_or_upgrade bazelisk
brew_install_or_upgrade boost
brew_install_or_upgrade ccache
brew_install_or_upgrade clang-format
brew_install_or_upgrade cmake
brew_install_or_upgrade coreutils
brew_install_or_upgrade docker
brew_install_or_upgrade docker-credential-helper-ecr
brew_install_or_upgrade fastlane
brew_install_or_upgrade ffmpeg
brew_install_or_upgrade flac
brew_install_or_upgrade fmt
brew_install_or_upgrade gh
brew_install_or_upgrade git
brew_install_or_upgrade git-lfs
brew_install_or_upgrade gnupg
brew_install_or_upgrade go
brew_install_or_upgrade groovy
brew_install_or_upgrade hashicorp/tap/packer
brew_install_or_upgrade htop
brew_install_or_upgrade imagemagick
brew_install_or_upgrade jq
brew_install_or_upgrade julia
brew_install_or_upgrade llvm
brew_install_or_upgrade lua
brew_install_or_upgrade neofetch
brew_install_or_upgrade ninja
brew_install_or_upgrade node
brew_install_or_upgrade p7zip
brew_install_or_upgrade pandoc
brew_install_or_upgrade pinentry-mac
brew_install_or_upgrade pipx
brew_install_or_upgrade portaudio
brew_install_or_upgrade portmidi
brew_install_or_upgrade postgresql
brew_install_or_upgrade pre-commit
brew_install_or_upgrade pyenv
brew_install_or_upgrade python
brew_install_or_upgrade readline
brew_install_or_upgrade ripgrep
brew_install_or_upgrade ruby
brew_install_or_upgrade rustup-init
brew_install_or_upgrade shellcheck
brew_install_or_upgrade shfmt
brew_install_or_upgrade speedtest-cli
brew_install_or_upgrade sqlite
brew_install_or_upgrade swiftlint
brew_install_or_upgrade taglib
brew_install_or_upgrade tree
brew_install_or_upgrade wget
brew_install_or_upgrade xcbeautify
brew_install_or_upgrade zlib
brew_install_or_upgrade zsh

brew install oven-sh/bun/bun

brew tap hashicorp/tap
brew_install_or_upgrade hashicorp/tap/terraform

print_magenta "Installing apps..."
brew tap homebrew/cask-fonts
brew tap homebrew/cask-drivers
brew_cask_install_or_upgrade chromedriver
brew_cask_install_or_upgrade docker
brew_cask_install_or_upgrade dotnet-sdk
brew_cask_install_or_upgrade dropbox
brew_cask_install_or_upgrade fig
brew_cask_install_or_upgrade font-jetbrains-mono
brew_cask_install_or_upgrade github
brew_cask_install_or_upgrade google-chrome
brew_cask_install_or_upgrade istat-menus
brew_cask_install_or_upgrade iterm2
brew_cask_install_or_upgrade jetbrains-toolbox
brew_cask_install_or_upgrade libreoffice
brew_cask_install_or_upgrade logitech-options
brew_cask_install_or_upgrade mactex
brew_cask_install_or_upgrade microsoft-office
brew_cask_install_or_upgrade microsoft-teams
brew_cask_install_or_upgrade monodraw
brew_cask_install_or_upgrade obs
brew_cask_install_or_upgrade powershell
brew_cask_install_or_upgrade spotify
brew_cask_install_or_upgrade sublime-merge
brew_cask_install_or_upgrade suspicious-package
brew_cask_install_or_upgrade temurin
brew_cask_install_or_upgrade tex-live-utility
brew_cask_install_or_upgrade tg-pro
brew_cask_install_or_upgrade visual-studio-code
brew_cask_install_or_upgrade vlc

print_magenta "Finish brewing..."
brew cleanup -ns
brew cleanup -s

print_magenta "Installing Xcode..."
brew robotsandpencils/made/xcodes
sudo xcodes install --latest

if brew ls --versions llvm; then
    # link clang-tidy to path
    ln -s "$(brew --prefix)/opt/llvm/bin/clang-tidy" "$(brew --prefix)/bin/clang-tidy"
fi

print_magenta "Install Rust"
rustup-init -y
source "$HOME/.cargo/env"
"$HOME/.cargo/bin/rustup" --version
"$HOME/.cargo/bin/rustup" update
"$HOME/.cargo/bin/rustc" --version

print_magenta "Installing Python packages..."
"$(brew --prefix)/bin/python3" --version
# Brew now manages the global python environment,
# and to install system-wide packages, you need to use brew (or pipx)
brew_install_or_upgrade ansible
brew_install_or_upgrade black
brew_install_or_upgrade isort
brew_install_or_upgrade rich
brew_install_or_upgrade ruff
brew_install_or_upgrade uv
brew_install_or_upgrade yt-dlp

pipx install aws-mfa
pipx install cmakelang
pipx install coverage
pipx install poetry
pipx install pygments
pipx install pytest

# Add alias for python
echo 'alias python=python3' >> "$SHELL_PROFILE"

# Poetry tab completion for Oh My Zsh
mkdir "$ZSH_CUSTOM/plugins/poetry"
poetry completions zsh > "$ZSH_CUSTOM/plugins/poetry/_poetry"

print_magenta "Setup PATH..."
if ! grep -q "$(brew --prefix)/opt/ruby/bin" < "$SHELL_PROFILE"; then
    echo "Adding brew ruby to path: $(brew --prefix)/opt/ruby/bin"
    echo "export PATH=\"$(brew --prefix)/opt/ruby/bin:\$PATH\"" >> "$SHELL_PROFILE"
fi
# shellcheck disable=SC1090
source "$SHELL_PROFILE"

RUBY_API_VERSION=$(ruby -e 'print Gem.ruby_api_version')
if ! echo "$PATH" | grep -q "$(brew --prefix)/lib/ruby/gems/$RUBY_API_VERSION/bin"; then
    # gem binaries go to here by default, so add it to path
    echo "Adding ruby gems to path: $(brew --prefix)/lib/ruby/gems/$RUBY_API_VERSION/bin"
    echo "export PATH=\$PATH:$(brew --prefix)/lib/ruby/gems/$RUBY_API_VERSION/bin" >> "$SHELL_PROFILE"
fi
# shellcheck disable=SC1090
source "$SHELL_PROFILE"

print_magenta "Checking brew Ruby version..."
echo "ruby: $(which ruby) $(ruby --version)"
echo "gem: $(which gem) $(gem --version)"

echo "Update gem and install bundler..."
gem update --system
gem install bundler --no-document

print_magenta "Setup gem..."
mkdir -p ~/.gem
echo ":backtrace: false
:bulk_threshold: 1000
:sources:
- https://rubygems.org/
:update_sources: true
:verbose: true
gem: --no-document" > ~/.gemrc
chmod 600 ~/.gemrc

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
*.pdb
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
git config --global fetch.parallel 0
git config --global fetch.prune true
git config --global fetch.prunetags true
git config --global init.defaultBranch main
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"

print_magenta "git config:"
git config --global --list

print_magenta "Setup GnuPG..."
mkdir -p ~/.gnupg
# pinentry allows storing gpg key passwords to Apple keychain so you don't have to type it everytime
echo "pinentry-program $(brew --prefix)/bin/pinentry-mac" > ~/.gnupg/gpg-agent.conf
# Fix permissions
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
    echo "Setting ssh config..."
    echo "
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $SSH_KEY" >> ~/.ssh/config
fi

print_magenta "Adding ssh key to GitHub..."
if [ ! -e "$SSH_KEY.pub" ]; then
    print_error_and_exit "Public key not found: $SSH_KEY.pub"
fi
# use GitHub CLI if available
if [ -n "$(command -v gh)" ]; then
    echo "Adding ssh key with name: $COMPUTER_ID"
    gh auth login --web --hostname github.com --git-protocol https --scopes admin:public_key,admin:gpg_key
    gh ssh-key add "$SSH_KEY.pub" --title "$COMPUTER_ID"
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
    print_green "Found gpg key $GPG_KEY, importing..."
    gpg --import "$GPG_KEY"
    git config --global user.signingkey "$GPG_KEY_ID"
    git config --global commit.gpgsign true
    if [ -n "$(command -v gh)" ]; then
        echo "Adding gpg key to GitHub"
        gh auth status
        gpg --armor --export "$GPG_KEY_ID" | gh gpg-key add -
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

# Note to self: get full list of repos using
# > gh repo list --json url | jq -r '.[].url'
# get ssh clone urls with:
# > for file in $(gh repo list --json nameWithOwner --jq '.[].nameWithOwner'); do echo \"git@github.com:$file\"; done
git clone "git@github.com:Esgrove/AudioBatch"
git clone "git@github.com:Esgrove/Esgrove"
git clone "git@github.com:Esgrove/fastapi-template"
git clone "git@github.com:Esgrove/fdo_randomizer"
git clone "git@github.com:Esgrove/JUCE"
git clone "git@github.com:Esgrove/othellogame"
git clone "git@github.com:Esgrove/playlist_formatter"
git clone "git@github.com:Esgrove/recordpool-dl"
git clone "git@github.com:Esgrove/rust-axum-example"
git clone "git@github.com:Esgrove/track-rename"

print_green "Installation done!"
neofetch

print_magenta "Next steps:"
print_magenta "Use brew zsh:"
print_yellow "sudo chsh -s $(brew --prefix)/bin/zsh"

print_magenta "Install oh-my-zsh:"
print_yellow 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"'

print_magenta "Restart"
print_yellow "sudo shutdown -r now"
