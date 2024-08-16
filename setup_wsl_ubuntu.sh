#!/bin/bash
set -eo pipefail

# Setup WSL Ubuntu

GIT_NAME="Esgrove"
GIT_EMAIL="esgrove@outlook.com"
SSH_KEY="$HOME/.ssh/id_ed25519"
SHELL_PROFILE="$HOME/.profile"
# Computer ID to use in GitHub
COMPUTER_ID="$GIT_NAME $(hostnamectl | grep "Static hostname" | awk '{print $3}') WSL $(date +%Y-%m-%d)"

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

# Function to install or upgrade a package
install_or_upgrade() {
    if sudo apt list --installed "$1" &> /dev/null; then
        print_yellow "Updating $1"
        sudo apt upgrade "$1" -y
    else
        print_yellow "Installing $1"
        sudo apt install "$1" -y
    fi
}

install_go() {
    # "apt install golang-go" is outdated and broken :(

    # Fetch Go versions
    GO_VERSION="$(curl -s https://go.dev/dl/ | grep -oP -m 1 'go[0-9]+\.[0-9]+(\.[0-9]+)?')"

    # Ensure that we got a version number
    if [ -z "$GO_VERSION" ]; then
        print_error "Failed to get the latest Go version."
    else
        print_bold "Latest Go version: $GO_VERSION"
    fi

    # Download Go binary
    wget "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"

    # Remove any previous installation
    sudo rm -rf /usr/local/go

    # Extract the downloaded archive
    sudo tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz"

    # Clean up downloaded tarball
    rm "${GO_VERSION}.linux-amd64.tar.gz"

    if ! grep -q "export GOROOT=/usr/local/go" < "$SHELL_PROFILE"; then
        echo "Adding Go variables to path..."
        # Set up environment variables
        echo "export GOROOT=/usr/local/go" >> "$SHELL_PROFILE"
        echo "export GOPATH=$HOME/go" >> "$SHELL_PROFILE"
        echo "export PATH=\"\$PATH\":/usr/local/go/bin:$GOPATH/bin" >> "$SHELL_PROFILE"
        source "$SHELL_PROFILE"
    fi

    # Verify the installation
    which go
    go version
}

install_kotlin() {
    # https://sdkman.io/install
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk version
    sdk install kotlin
    sdk install gradle
}

install_swift() {
    UBUNTU_OS="ubuntu2404"
    UBUNTU_VER="ubuntu24.04"
    SWIFT_VERSION="5.10.1"

    if [ -n "$(command -v swift)" ]; then
        local EXISTING_SWIFT_VERSION
        EXISTING_SWIFT_VERSION=$(swift --version | grep -oP 'Swift version \K[0-9]+\.[0-9]+\.[0-9]+')
        if [ "$EXISTING_SWIFT_VERSION" = "$SWIFT_VERSION" ]; then
            print_yellow "Swift $SWIFT_VERSION already installed, skipping..."
            return
        fi
    fi

    # Download Swift
    # https://download.swift.org/swift-5.10.1-release/ubuntu2404/swift-5.10.1-RELEASE/swift-5.10.1-RELEASE-ubuntu24.04.tar.gz
    SWIFT_URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/${UBUNTU_OS}/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-${UBUNTU_VER}.tar.gz"
    wget "$SWIFT_URL"

    # Extract Swift
    tar xzf swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04.tar.gz

    # Move Swift to /usr/local
    sudo mv swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04 /usr/local/swift

    sudo ln -s /usr/local/swift/usr/bin/swift /usr/bin/swift

    # Clean up downloaded tarball
    rm swift-${SWIFT_VERSION}-RELEASE-${UBUNTU_VER}.tar.gz

    # Verify the installation
    which swift
    swift --version
}

install_rust() {
    if [ -z "$(command -v rustup)" ]; then
        print_magenta "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        print_yellow "rustup already installed, updating rustc..."
    fi
    rustup --version
    rustup self update
    rustup update
    rustc --version
}

install_docker() {
    # https://docs.docker.com/desktop/install/linux-install/
    # Add Docker's official GPG key:
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

print_green "Setting up WSL Ubuntu for $GIT_NAME <$GIT_EMAIL>"
echo "ID: $COMPUTER_ID"

cd "$HOME"
echo "$(whoami) $(pwd)"
source "$HOME/.profile"

# Print info
hostnamectl
lsb_release -a

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2> /dev/null &

# Fix locale
sudo locale-gen en_US.UTF-8
locale -a

# Get rid of Ubuntu Pro adverts
sudo pro config set apt_news=false
sudo systemctl disable ubuntu-advantage

print_magenta "Setup shell profile..."
if [ -e wsl_profile.sh ]; then
    if grep -qF 'alias pirq' "$SHELL_PROFILE"; then
        print_yellow "shell profile already contains configs, skipping..."
    else
        tail -n +3 wsl_profile.sh >> "$SHELL_PROFILE"
    fi
else
    print_error "Missing shell profile 'wsl_profile.sh', skipping..."
fi

# Create developer dir
mkdir -p "$HOME/Developer"

# Use case-insensitive auto-completion
SETTING="set completion-ignore-case on"
FILE="$HOME/.inputrc"

if [ ! -f "$FILE" ]; then
    echo "$SETTING" > "$FILE"
else
    if ! grep -q "$SETTING" "$FILE"; then
        echo "$SETTING" >> "$FILE"
        echo "Enabled case-insensitive bash completion"
    fi
fi
# Apply the changes to the current session
bind -f "$FILE"

print_magenta "Installing packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    build-essential \
    ccache \
    clang \
    clang-format \
    clang-tidy \
    cmake \
    curl \
    default-jdk \
    dotnet-sdk-8.0 \
    ffmpeg \
    gh \
    git \
    git-lfs \
    gnupg \
    jq \
    libicu-dev \
    libssl-dev \
    neofetch \
    ninja-build \
    openssl \
    pinentry-curses \
    pipx \
    pkg-config \
    python3 \
    python3-pip \
    ripgrep \
    shellcheck \
    unzip \
    zip \
    zsh

#install_go
install_kotlin
install_swift
install_rust
install_docker

if ! grep -q "$HOME/.local/bin" < "$SHELL_PROFILE"; then
    echo "Adding pipx to path..."
    # Set up environment variables
    echo "export PATH=\"\$PATH\":$HOME/.local/bin" >> "$SHELL_PROFILE"
    source "$SHELL_PROFILE"
fi

print_magenta "Installing Python packages..."
# Install common Python packages
echo "$(python3 --version) from $(which python3)"
echo "pipx $(pipx --version) from $(which pipx)"

pipx install poetry
pipx install pygments
pipx install pytest
pipx install ruff
pipx install uv
pipx install yt-dlp

print_magenta "Creating global gitignore..."
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
cat ~/.gitignore

print_magenta "Setting up git..."
git --version
git-lfs --version
sudo git lfs install --system

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
echo "pinentry-program /usr/bin/pinentry-curses" > ~/.gnupg/gpg-agent.conf
# Fix permissions
chown -R "$(whoami)" ~/.gnupg/
chmod 600 ~/.gnupg/*
chmod 700 ~/.gnupg

if [ -e "$SSH_KEY" ]; then
    print_yellow "SSH key $SSH_KEY already exists, skipping key creation..."
else
    print_magenta "Creating SSH key..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY"
    echo "Setting ssh config..."
    echo "
Host *
  AddKeysToAgent yes
  IdentityFile $SSH_KEY" >> ~/.ssh/config
fi
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"
ssh-add -l

if [ ! -e "$SSH_KEY.pub" ]; then
    print_error_and_exit "Public key not found: $SSH_KEY.pub"
else
    echo "SSH public key:"
    cat "$SSH_KEY.pub"
fi

print_bold "Create access token for gh at https://github.com/settings/tokens and copy-paste here:"
read -r token

if [ -z "$token" ]; then
    print_yellow "Empty access token, skipping github cli auth and repo cloning..."
else
    export GITHUB_TOKEN=$token

    github_ssh_keys=$(gh ssh-key list)
    pub_ssh_key=$(awk '{print $2}' < "$SSH_KEY.pub")

    echo "Existing SSH keys:"
    echo "$github_ssh_keys"

    if echo "$github_ssh_keys" | grep -Fq "$pub_ssh_key"; then
        print_yellow "SSH key already exists in GitHub..."
    else
        print_magenta "Adding ssh key to GitHub..."
        echo "Using key name: $COMPUTER_ID"
        if ! gh ssh-key add "$SSH_KEY.pub" --title "$COMPUTER_ID"; then
            print_error "SSH key not added"
        fi
    fi

    print_magenta "Cloning repositories..."

    cd "$HOME/Developer"
    echo "Cloning to $(pwd)"

    # Note to self: get full list of repos using
    # > gh repo list --json url | jq -r '.[].url'
    # get ssh clone urls with:
    # > for file in $(gh repo list --json nameWithOwner --jq '.[].nameWithOwner'); do echo \"git@github.com:$file\"; done
    git clone "git@github.com:Esgrove/cli-tools"
    git clone "git@github.com:Esgrove/fastapi-template"
    git clone "git@github.com:Esgrove/othellogame"
    git clone "git@github.com:Esgrove/rust-axum-example"
fi

print_green "Installation done!"
neofetch
