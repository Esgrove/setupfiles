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
    local name="$1"
    if brew ls --versions "$name" > /dev/null; then
        if ! brew upgrade --formula "$name"; then
            print_yellow "Failed to upgrade $name, continuing..."
        fi
    else
        print_magenta "Installing $name"
        brew info "$name"
        if ! brew install --formula "$name"; then
            print_yellow "Failed to install $name, continuing..."
        fi
    fi
}

brew_cask_install_or_upgrade() {
    local name="$1"
    if brew ls --versions "$name" > /dev/null; then
        if ! brew upgrade --cask "$name"; then
            print_yellow "Failed to upgrade cask $name, continuing..."
        fi
    else
        print_magenta "Installing $name"
        brew info "$name"
        if ! brew install --cask "$name"; then
            print_yellow "Failed to install cask $name, continuing..."
        fi
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

touch "$SHELL_PROFILE"

# Create developer dir
mkdir -p "$HOME/Developer"

# Create AWS CLI dir
mkdir -p "$HOME/.aws"

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

print_magenta "Installing tools and libraries..."
brew tap hashicorp/tap
brew tap oven-sh/bun
brew tap cargo-lambda/cargo-lambda
brew tap localstack/tap

brew_install_or_upgrade zsh                # https://github.com/zsh-users/zsh

# Libraries
brew_install_or_upgrade autoconf
brew_install_or_upgrade automake
brew_install_or_upgrade ffmpeg             # https://github.com/FFmpeg/FFmpeg
brew_install_or_upgrade flac               # https://github.com/xiph/flac
brew_install_or_upgrade fmt                # https://github.com/fmtlib/fmt
brew_install_or_upgrade git                # https://github.com/git/git
brew_install_or_upgrade git-lfs            # https://github.com/git-lfs/git-lfs
brew_install_or_upgrade harfbuzz           # https://github.com/harfbuzz/harfbuzz
brew_install_or_upgrade jemalloc           # https://github.com/jemalloc/jemalloc
brew_install_or_upgrade make
brew_install_or_upgrade openssl@3
brew_install_or_upgrade pkgconf            # https://github.com/pkgconf/pkgconf
brew_install_or_upgrade qt                 # https://github.com/qt/qtbase
brew_install_or_upgrade wget

# Programming languages and compilers
brew_install_or_upgrade clojure            # https://github.com/clojure/clojure
brew_install_or_upgrade gcc
brew_install_or_upgrade ghc                # https://gitlab.haskell.org/ghc/ghc
brew_install_or_upgrade go                 # https://github.com/golang/go
brew_install_or_upgrade groovy             # https://github.com/apache/groovy
brew_install_or_upgrade julia              # https://github.com/JuliaLang/julia
brew_install_or_upgrade kotlin             # https://github.com/JetBrains/kotlin
brew_install_or_upgrade llvm               # https://github.com/llvm/llvm-project
brew_install_or_upgrade lua                # https://github.com/lua/lua
brew_install_or_upgrade protobuf           # https://github.com/protocolbuffers/protobuf
brew_install_or_upgrade python             # https://github.com/python/cpython
brew_install_or_upgrade python@3.11        # https://github.com/python/cpython
brew_install_or_upgrade python@3.12        # https://github.com/python/cpython
brew_install_or_upgrade python@3.13        # https://github.com/python/cpython
brew_install_or_upgrade python@3.9         # https://github.com/python/cpython
brew_install_or_upgrade ruby               # https://github.com/ruby/ruby
brew_install_or_upgrade rustup             # https://github.com/rust-lang/rustup
brew_install_or_upgrade zig                # https://github.com/ziglang/zig

# Runtimes
brew_install_or_upgrade bun                # https://github.com/oven-sh/bun
brew_install_or_upgrade deno               # https://github.com/denoland/deno
brew_install_or_upgrade node               # https://github.com/nodejs/node
brew_cask_install_or_upgrade dotnet-sdk    # https://github.com/dotnet/sdk
brew_cask_install_or_upgrade temurin       # https://adoptium.net

# Managers and build tools
brew_install_or_upgrade cmake              # https://github.com/Kitware/CMake
brew_install_or_upgrade gradle             # https://github.com/gradle/gradle
brew_install_or_upgrade leiningen          # https://github.com/technomancy/leiningen
brew_install_or_upgrade meson              # https://github.com/mesonbuild/meson
brew_install_or_upgrade ninja              # https://github.com/ninja-build/ninja
brew_install_or_upgrade pnpm               # https://github.com/pnpm/pnpm

# Databases
brew_install_or_upgrade postgresql         # https://github.com/postgres/postgres
brew_install_or_upgrade sqlite             # https://github.com/sqlite/sqlite

# CLI tools etc
brew_install_or_upgrade aria2              # https://github.com/aria2/aria2
brew_install_or_upgrade awscli             # https://github.com/aws/aws-cli
brew_install_or_upgrade azure-cli          # https://github.com/Azure/azure-cli
brew_install_or_upgrade bat                # https://github.com/sharkdp/bat
brew_install_or_upgrade cargo-lambda       # https://github.com/cargo-lambda/cargo-lambda
brew_install_or_upgrade cargo-nextest      # https://github.com/nextest-rs/nextest
brew_install_or_upgrade ccache             # https://github.com/ccache/ccache
brew_install_or_upgrade checkov            # https://github.com/bridgecrewio/checkov
brew_install_or_upgrade clang-format       # https://github.com/llvm/llvm-project
brew_install_or_upgrade coreutils          # https://github.com/coreutils/coreutils
brew_install_or_upgrade erdtree            # https://github.com/solidiquis/erdtree
brew_install_or_upgrade fastlane           # https://github.com/fastlane/fastlane
brew_install_or_upgrade fd                 # https://github.com/sharkdp/fd
brew_install_or_upgrade fzf                # https://github.com/junegunn/fzf
brew_install_or_upgrade gh                 # https://github.com/cli/cli
brew_install_or_upgrade ghostscript        # https://www.ghostscript.com
brew_install_or_upgrade gnupg              # https://github.com/gpg/gnupg
brew_install_or_upgrade golangci-lint      # https://github.com/golangci/golangci-lint
brew_install_or_upgrade gti                # https://github.com/rwos/gti
brew_install_or_upgrade helm               # https://github.com/helm/helm
brew_install_or_upgrade htop               # https://github.com/htop-dev/htop
brew_install_or_upgrade hyperfine          # https://github.com/sharkdp/hyperfine
brew_install_or_upgrade imagemagick        # https://github.com/ImageMagick/ImageMagick
brew_install_or_upgrade jq                 # https://github.com/jqlang/jq
brew_install_or_upgrade ktlint             # https://github.com/pinterest/ktlint
brew_install_or_upgrade kubernetes-cli     # https://github.com/kubernetes/kubectl
brew_install_or_upgrade localstack-cli     # https://github.com/localstack/localstack
brew_install_or_upgrade minikube           # https://github.com/kubernetes/minikube
brew_install_or_upgrade nghttp2            # https://github.com/nghttp2/nghttp2
brew_install_or_upgrade pandoc             # https://github.com/jgm/pandoc
brew_install_or_upgrade pinentry-mac       # https://github.com/GPGTools/pinentry-mac
brew_install_or_upgrade pre-commit         # https://github.com/pre-commit/pre-commit
brew_install_or_upgrade ripgrep            # https://github.com/BurntSushi/ripgrep
brew_install_or_upgrade sccache            # https://github.com/mozilla/sccache
brew_install_or_upgrade shellcheck         # https://github.com/koalaman/shellcheck
brew_install_or_upgrade shfmt              # https://github.com/mvdan/sh
brew_install_or_upgrade swiftformat        # https://github.com/nicklockwood/SwiftFormat
brew_install_or_upgrade swiftlint          # https://github.com/realm/SwiftLint
brew_install_or_upgrade taglib             # https://github.com/taglib/taglib
brew_install_or_upgrade hashicorp/tap/terraform  # https://github.com/hashicorp/terraform
brew_install_or_upgrade tex-fmt            # https://github.com/WGUNDERWOOD/tex-fmt
brew_install_or_upgrade tflint             # https://github.com/terraform-linters/tflint
brew_install_or_upgrade tree
brew_install_or_upgrade typst              # https://github.com/typst/typst
brew_install_or_upgrade wrk                # https://github.com/wg/wrk
brew_install_or_upgrade xcbeautify         # https://github.com/thii/xcbeautify
brew_install_or_upgrade yarn               # https://github.com/yarnpkg/yarn
brew_install_or_upgrade yazi               # https://github.com/sxyazi/yazi

print_magenta "Installing apps..."
brew_cask_install_or_upgrade affinity-designer
brew_cask_install_or_upgrade affinity-photo
brew_cask_install_or_upgrade affinity-publisher
brew_cask_install_or_upgrade chatgpt
brew_cask_install_or_upgrade discord
brew_cask_install_or_upgrade docker
brew_cask_install_or_upgrade dropbox
brew_cask_install_or_upgrade firefox
brew_cask_install_or_upgrade google-chrome
brew_cask_install_or_upgrade google-cloud-sdk
brew_cask_install_or_upgrade ilok-license-manager
brew_cask_install_or_upgrade iterm2
brew_cask_install_or_upgrade jetbrains-toolbox
brew_cask_install_or_upgrade libreoffice
brew_cask_install_or_upgrade logi-options+
brew_cask_install_or_upgrade microsoft-office
brew_cask_install_or_upgrade monodraw
brew_cask_install_or_upgrade obs
brew_cask_install_or_upgrade powershell
brew_cask_install_or_upgrade reaper
brew_cask_install_or_upgrade slack
brew_cask_install_or_upgrade slack-cli
brew_cask_install_or_upgrade spotify
brew_cask_install_or_upgrade sublime-merge
brew_cask_install_or_upgrade suspicious-package
brew_cask_install_or_upgrade tg-pro
brew_cask_install_or_upgrade visual-studio-code
brew_cask_install_or_upgrade vlc
brew_cask_install_or_upgrade warp
brew_cask_install_or_upgrade zed
brew_cask_install_or_upgrade zoom

print_magenta "Installing fonts..."
brew_cask_install_or_upgrade font-commit-mono
brew_cask_install_or_upgrade font-jetbrains-mono
brew_cask_install_or_upgrade font-roboto
brew_cask_install_or_upgrade font-roboto-mono

print_magenta "Finish brewing..."
brew cleanup -ns
brew cleanup -s

if brew ls --versions llvm; then
    # link clang-tidy to path
    ln -s "$(brew --prefix)/opt/llvm/bin/clang-tidy" "$(brew --prefix)/bin/clang-tidy"
fi

print_magenta "Install Rust..."
rustup-init -y
source "$HOME/.cargo/env"
"$HOME/.cargo/bin/rustup" --version
"$HOME/.cargo/bin/rustc" --version
"$HOME/.cargo/bin/rustup" update

print_magenta "Install Rust packages..."
cargo install cargo-tarpaulin                                   # https://github.com/xd009642/tarpaulin
cargo install cross --git https://github.com/cross-rs/cross
cargo install nitor-vault

print_magenta "Installing Python packages..."
"$(brew --prefix)/bin/python3" --version
echo "$(uv --version) from $(which uv)"

uv tool install aws-mfa
uv tool install coverage
uv tool install maturin
uv tool install nameless-deploy-tools
uv tool install nitor-vault
uv tool install poetry
uv tool install pygments
uv tool install pytest
uv tool install ruff
uv tool install yt-dlp

print_magenta "Installing nvm..."
# https://github.com/nvm-sh/nvm
PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'

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
git clone "git@github.com:Esgrove/axum-example"
git clone "git@github.com:Esgrove/bandcamp-dl"
git clone "git@github.com:Esgrove/cli-tools"
git clone "git@github.com:Esgrove/Esgrove"
git clone "git@github.com:Esgrove/fastapi-template"
git clone "git@github.com:Esgrove/fdo-dj-opas"
git clone "git@github.com:Esgrove/fdo-randomizer"
git clone "git@github.com:Esgrove/fixed_deque"
git clone "git@github.com:Esgrove/JUCE"
git clone "git@github.com:Esgrove/othellogame"
git clone "git@github.com:Esgrove/playlist-formatter"
git clone "git@github.com:Esgrove/recordpool-dl"
git clone "git@github.com:Esgrove/track-rename"

git clone "git@github.com:NitorCreations/aws-infra.git"
git clone "git@github.com:NitorCreations/indoor-location-mist-websocket.git"
git clone "git@github.com:NitorCreations/ironbank-web.git"
git clone "git@github.com:NitorCreations/ironbank.git"
git clone "git@github.com:NitorCreations/nameless-deploy-tools.git"
git clone "git@github.com:NitorCreations/nitor-devel-backend.git"
git clone "git@github.com:NitorCreations/pynitor.git"
git clone "git@github.com:NitorCreations/repository-conf.git"
git clone "git@github.com:NitorCreations/vault.git"

print_magenta "Configuring Nitor package repositories..."
cd repository-conf
./configure_repos.py

cd ../nameless-deploy-tools
./faster_register_complete.sh

# TODO:
# crates.io token
# PyPI token

print_green "Installation done!"

print_magenta "Next steps:"
print_magenta "Use brew zsh:"
print_yellow "sudo chsh -s $(brew --prefix)/bin/zsh"

print_magenta "Install oh-my-zsh:"
# https://github.com/ohmyzsh/ohmyzsh
print_yellow 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"'

print_magenta "Poetry tab completion for Oh My Zsh:"
print_yellow 'mkdir "$ZSH_CUSTOM/plugins/poetry"'
print_yellow 'poetry completions zsh > "$HOME/.oh-my-zsh/custom/plugins/poetry/_poetry"'

print_magenta "Vault tab completion for Oh My Zsh:"
print_yellow 'mkdir "$ZSH_CUSTOM/plugins/vault"'
print_yellow 'vault completion zsh > "$$HOME/.oh-my-zsh/custom/plugins/vault/_vault"'

print_magenta "Restart"
print_yellow "sudo shutdown -r now"
