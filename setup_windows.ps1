# Setup new Windows machine
# Note: Run as Administrator

$GIT_NAME = "Esgrove"
$GIT_EMAIL = "esgrove@outlook.com"
$SSH_KEY = "$env:USERPROFILE\.ssh\id_ed25519"
$SSH_KEY_PUB = "$SSH_KEY.pub"

# Reload PATH
function Update-Path {
    $Env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')
}

# Add path to system PATH
function Add-Path {
    param(
        [Parameter()]
        [string]$PathToAdd
    )

    $newPath = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + $PathToAdd
    [Environment]::SetEnvironmentVariable('PATH', $newPath, 'Machine')
}

# Run a command and throw an error if the exit code is non-zero.
function Invoke-CommandOrThrow() {
    if ($args.Count -eq 0) {
        throw 'No arguments given.'
    }

    $command = $args[0]
    $commandArgs = @()
    if ($args.Count -gt 1) {
        $commandArgs = $args[1..($args.Count - 1)]
    }

    & $command $commandArgs
    $result = $LASTEXITCODE

    if ($result -ne 0) {
        throw "$command $commandArgs exited with code $result."
    }
}

# Check for admin Powershell
function Test-Elevated {
    # Get the ID and security principal of the current user account
    $myIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myPrincipal = new-object System.Security.Principal.WindowsPrincipal($myIdentity)
    # Check to see if we are currently running as Administrator
    return $myPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check to see if we are currently running as Administrator
if (!(Test-Elevated)) {
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);
    exit
}

Write-Host "Setup Windows..." -ForegroundColor "Yellow"

Write-Output "Public IP: "
(Invoke-WebRequest -uri "http://ifconfig.me/ip" -UseBasicParsing).Content

# Enable Long Paths in Windows
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force

# Restore full context menu for Windows 11
reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve

# General: Disable Application launch tracking: Enable: 1, Disable: 0
Set-ItemProperty "HKCU:\\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start-TrackProgs" 0

# General: Disable SmartScreen Filter: Enable: 1, Disable: 0
Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" "EnableWebContentEvaluation" 0

# Sound: Disable Startup Sound
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStartupSound" 1
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" "DisableStartupSound" 1

# Ensure necessary registry paths
if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) { New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Type Folder | Out-Null }
if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState")) { New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Type Folder | Out-Null }
if (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Windows Search")) { New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Windows Search" -Type Folder | Out-Null }

# Explorer: Show file extensions by default
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0

# Explorer: Show path in title bar
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" "FullPath" 1

# Explorer: Avoid creating Thumbs.db files on network volumes
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "DisableThumbnailsOnNetworkFolders" 1

# Uninstall Solitaire
Get-AppxPackage "Microsoft.MicrosoftSolitaireCollection" -AllUsers | Remove-AppxPackage
Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.MicrosoftSolitaireCollection" | Remove-AppxProvisionedPackage -Online

# Uninstall Voice Recorder
Get-AppxPackage "Microsoft.WindowsSoundRecorder" -AllUsers | Remove-AppxPackage
Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.WindowsSoundRecorder" | Remove-AppxProvisionedPackage -Online

Write-Host "Installing apps and tools..." -ForegroundColor "Yellow"

# Install Chocolatey
# https://docs.chocolatey.org/en-us/choco/setup#install-with-powershell.exe
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco --version
choco feature enable -n allowGlobalConfirmation

# https://community.chocolatey.org/packages/InnoSetup
Invoke-CommandOrThrow choco install innosetup
# https://community.chocolatey.org/packages/visualstudio2022community
Invoke-CommandOrThrow choco install visualstudio2022community --package-parameters '--add Microsoft.VisualStudio.Workload.VCTools;includeRecommended --add Microsoft.VisualStudio.Component.VC.ATL'
# Alternatively just the MSVC build tools without IDE...
# https://community.chocolatey.org/packages/visualstudio2022buildtools
# Invoke-CommandOrThrow choco install visualstudio2022buildtools --package-parameters '--add Microsoft.VisualStudio.Workload.VCTools;includeRecommended --add Microsoft.VisualStudio.Component.VC.ATL'

# Winget for reference, choco still seems the better choice for now (12/2022)...
#winget install -e --id Git.Git --source winget
#winget install -e --id Kitware.CMake

winget install -e --id Microsoft.AzureCLI
winget install -e --id Swift.Toolchain

# https://scoop.sh/
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

Update-Path

scoop install 7zip
scoop install ccache
scoop install cmake
scoop install dotnet-sdk
scoop install ffmpeg
scoop install gh
scoop install ghostscript
scoop install git
scoop install go
scoop install gradle
scoop install gradle
scoop install jq
scoop install ninja
scoop install openssl
scoop install python
scoop install ripgrep
scoop install rustup
scoop install shellcheck
scoop install shfmt
scoop install wget

scoop bucket add extras
scoop install extras/firefox
scoop install extras/googlechrome
scoop install extras/jetbrains-toolbox
scoop install extras/sublime-merge
scoop install extras/vlc
scoop install extras/vscode
scoop install extras/wiztree

scoop bucket add java
scoop install java/temurin-jdk

scoop bucket add nerd-fonts
scoop install nerd-fonts/JetBrains-Mono

Write-Output "Choco installs finished, refreshing env variables..."
# Make `refreshenv` available right away, by defining the $env:ChocolateyInstall
# variable and importing the Chocolatey profile module.
# Note: Using `. $PROFILE` instead *may* work, but isn't guaranteed to.
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
# refresh environment vars
# https://docs.chocolatey.org/en-us/create/functions/update-sessionenvironment
refreshenv

Write-Host "Checking package versions..." -ForegroundColor "Yellow"
cmake --version
dotnet --version
gh --version
git --version
java -version
python --version
rustup --version
$(7z i)[0..5]

powershell -c "irm https://astral.sh/uv/0.3.0/install.ps1 | iex"

Write-Host "Installing Rust..." -ForegroundColor "Yellow"
rustup update

Add-Path "C:\Users\faksu\AppData\Roaming\Python\Scripts"

Write-Host "Installing Python packages..." -ForegroundColor "Yellow"
python.exe -m pip install --upgrade pip setuptools wheel

# uv install python packages
uv tool install poetry
uv tool install pygments
uv tool install pytest
uv tool install ruff
uv tool install yt-dlp

# Needed for Ruby gems: use Ruby ridk to update the system and install development toolchain
ridk install 2 3

Update-SessionEnvironment
Update-Path

Write-Output "Installing Bundler and Fastlane"
gem update --system
gem install bundler --no-document
gem install fastlane --no-document

Write-Host "Setup git..." -ForegroundColor "Yellow"

$global_ignore_file = Join-Path $env:USERPROFILE -ChildPath ".gitignore"
New-Item $global_ignore_file -Type File -Force -Value @"
__pycache__/
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
Thumbs.db
"@

git config --global advice.detachedHead false
git config --global core.autocrlf input
git config --global core.excludesfile "$global_ignore_file"
git config --global core.longpaths true
git config --global core.symlinks true
git config --global fetch.parallel 0
git config --global fetch.prune true
git config --global fetch.prunetags true
git config --global init.defaultBranch main
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"

Write-Host "git config:"
git config --global --list

Write-Host "Creating bash profile..."
New-Item ~\.bashrc -Type File
Copy-Item -Path .\bashrc.sh -Destination ~\.bashrc -Force

# Install OpenSSH and setup SSH key
Write-Host "Setup SSH..." -ForegroundColor "Yellow"
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

Get-Service -Name sshd | Set-Service -StartupType Automatic
Start-Service sshd
Get-Service sshd

Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
Get-Service ssh-agent

Write-Output "Creating SSH key..."
New-Item -Path "$env:USERPROFILE\.ssh" -ItemType Directory -Force
ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY"
ssh-add "$SSH_KEY"

Write-Host "Adding SSH key to GitHub..." -ForegroundColor "Yellow"
# Uses GitHub CLI
gh auth login --web --hostname github.com --git-protocol https --scopes admin:public_key
gh ssh-key add "$SSH_KEY_PUB" --title "$env:computername"

Write-Host "Cloning repos..." -ForegroundColor "Yellow"
New-Item -Path ~\Developer -ItemType Directory
Set-Location -Path ~\Developer
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
