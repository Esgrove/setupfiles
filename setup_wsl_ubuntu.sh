#!/bin/bash
set -eo pipefail

# Setup WSL Ubuntu

# Copy files to Ubuntu
# cp /mnt/c/Users/YourUsername/Desktop/yourscript.sh ~/

GIT_NAME="Esgrove"
GIT_EMAIL="esgrove@outlook.com"
SSH_KEY="$HOME/.ssh/id_ed25519"
GPG_KEY="$HOME/esgrove-gpg-wsl-private-key.asc"
GPG_KEY_ID=""
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

print_green "Setting up WSL Ubuntu for $GIT_NAME <$GIT_EMAIL>"
echo "ID: $COMPUTER_ID"

cd ~
echo "$(whoami) $(pwd)"
source ~/.profile

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

print_magenta "Setup shell profile..."
if [ -e wsl_profile.sh ]; then
    if grep -qF 'alias pirq' ~/.profile; then
        print_yellow "shell profile already contains configs, skipping..."
    else
        tail -n +3 wsl_profile.sh >> ~/.profile
    fi
else
    print_yellow "Missing shell profile 'wsl_profile.sh', skipping"
fi

# Create developer dir
mkdir -p "$HOME/Developer"

print_magenta "Installing packages..."
sudo apt update && sudo apt upgrade
install_or_upgrade cmake
install_or_upgrade ffmpeg
install_or_upgrade gh
install_or_upgrade git
install_or_upgrade git-lfs
install_or_upgrade gnupg
install_or_upgrade jq
install_or_upgrade neofetch
install_or_upgrade neofetch
install_or_upgrade ninja-build
install_or_upgrade pinentry-curses
install_or_upgrade python3
install_or_upgrade python3-pip
install_or_upgrade pipx
install_or_upgrade ripgrep
install_or_upgrade shellcheck
install_or_upgrade zsh

print_magenta "Installing Python packages..."
# Install Python packages
python3 --version
python3 -m pip install --upgrade pip setuptools wheel
echo "black
certifi
click
colorama
isort
matplotlib
numpy
pandas
pillow
playwright
pygments
pytest
pyupgrade
requests
rich
selenium
speedtest-cli
tqdm
typer[all]
webdriver-manager
yt-dlp" > ~/python_packages.txt
python3 -m pip install -r ~/python_packages.txt

if [ -z "$(command -v rustup)" ]; then
    print_magenta "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    print_yellow "rustup already installed, updating rustc..."
fi
rustup --version
rustup update
rustc --version

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

print_magenta "Installing Poetry..."
pipx install poetry

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
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY"
    echo "Setting ssh config..."
    echo "
Host *
  AddKeysToAgent yes
  IdentityFile $SSH_KEY" >> ~/.ssh/config
fi

print_magenta "Adding ssh key to GitHub..."
if [ ! -e "$SSH_KEY.pub" ]; then
    print_error_and_exit "Public key not found: $SSH_KEY.pub"
else
    echo "SSH public key:"
    cat "$SSH_KEY.pub"
fi

print_bold "Create access token for gh and copy-paste here:"
read -r token

if [ -z "$token" ]; then
    print_yellow "Empty access token, skipping github cli auth and repo cloning..."
else
    export GITHUB_TOKEN=$token

    echo "Adding ssh key with name: $COMPUTER_ID"
    gh ssh-key add "$SSH_KEY.pub" --title "$COMPUTER_ID"

    print_magenta "Cloning repositories..."

    cd "$HOME/Developer"
    echo "Cloning to $(pwd)"

    # Note to self: get full list of repos using
    # > gh repo list --json url | jq -r '.[].url'
    # get ssh clone urls with:
    # > for file in $(gh repo list --json nameWithOwner --jq '.[].nameWithOwner'); do echo \"git@github.com:$file\"; done
    git clone "git@github.com:Esgrove/fastapi-template"
    git clone "git@github.com:Esgrove/othellogame"
    git clone "git@github.com:Esgrove/playlist_formatter"
    git clone "git@github.com:Esgrove/rust-axum-example"
fi

print_green "Installation done!"
neofetch
