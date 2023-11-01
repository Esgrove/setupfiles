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

# https://community.chocolatey.org/packages/git
Invoke-CommandOrThrow choco install git
# https://community.chocolatey.org/packages/gh
Invoke-CommandOrThrow choco install gh
# https://community.chocolatey.org/packages/cmake
Invoke-CommandOrThrow choco install cmake --installargs 'ADD_CMAKE_TO_PATH=System'
# https://community.chocolatey.org/packages/GoogleChrome
Invoke-CommandOrThrow choco install googlechrome
# https://community.chocolatey.org/packages/Firefox
Invoke-CommandOrThrow choco install firefox
# https://community.chocolatey.org/packages/InnoSetup
Invoke-CommandOrThrow choco install innosetup
# https://community.chocolatey.org/packages/python
Invoke-CommandOrThrow choco install python --version=3.11.4
# https://community.chocolatey.org/packages/ccache
Invoke-CommandOrThrow choco install ccache
# https://community.chocolatey.org/packages/7zip
Invoke-CommandOrThrow choco install 7zip
# https://community.chocolatey.org/packages/ninja
Invoke-CommandOrThrow choco install ninja
# https://community.chocolatey.org/packages/jq
Invoke-CommandOrThrow choco install jq
# https://community.chocolatey.org/packages/ripgrep
Invoke-CommandOrThrow choco install ripgrep
# https://community.chocolatey.org/packages/shellcheck
Invoke-CommandOrThrow choco install shellcheck
# https://community.chocolatey.org/packages/shfmt/
Invoke-CommandOrThrow choco install shfmt
# https://community.chocolatey.org/packages/gradle
Invoke-CommandOrThrow choco install gradle
# https://community.chocolatey.org/packages/openssl
Invoke-CommandOrThrow choco install openssl
# https://community.chocolatey.org/packages/Ghostscript
Invoke-CommandOrThrow choco install ghostscript
# https://community.chocolatey.org/packages/ffmpeg
Invoke-CommandOrThrow choco install ffmpeg
# https://community.chocolatey.org/packages/sublimemerge
Invoke-CommandOrThrow choco install sublimemerge
# https://community.chocolatey.org/packages/dotnet-sdk
Invoke-CommandOrThrow choco install dotnet-sdk --version=7.0.403
# https://community.chocolatey.org/packages/Temurin
Invoke-CommandOrThrow choco install temurin
# https://community.chocolatey.org/packages/ruby
Invoke-CommandOrThrow choco install ruby
# Needed for Ruby gems
# https://community.chocolatey.org/packages/msys2
Invoke-CommandOrThrow choco install msys2 --params "/NoUpdate"
# https://community.chocolatey.org/packages/rustup.install
Invoke-CommandOrThrow choco install rustup.install
# https://community.chocolatey.org/packages/golang
Invoke-CommandOrThrow choco install golang
# https://community.chocolatey.org/packages/wiztree
Invoke-CommandOrThrow choco install wiztree
# https://community.chocolatey.org/packages/vlc
Invoke-CommandOrThrow choco install vlc
# https://community.chocolatey.org/packages/vscode
Invoke-CommandOrThrow choco install vscode
# https://community.chocolatey.org/packages/visualstudio2022buildtools
# Invoke-CommandOrThrow choco install visualstudio2022buildtools --package-parameters '--add Microsoft.VisualStudio.Workload.VCTools;includeRecommended --add Microsoft.VisualStudio.Component.VC.ATL'
# https://community.chocolatey.org/packages/visualstudio2022community
Invoke-CommandOrThrow choco install visualstudio2022community --package-parameters '--add Microsoft.VisualStudio.Workload.VCTools;includeRecommended --add Microsoft.VisualStudio.Component.VC.ATL'

# Winget for reference, choco still seems the better choice for now (12/2022)...
#winget install --id Git.Git -e --source winget
#winget install --id Kitware.CMake -e

Update-Path

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

Write-Host "Installing Rust..." -ForegroundColor "Yellow"
rustup update

# Install Poetry
# https://python-poetry.org/docs/master/#installing-with-the-official-installer
(Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | python -

Write-Host "Installing Python packages..." -ForegroundColor "Yellow"
python.exe -m pip install --upgrade pip setuptools wheel
Add-Path "C:\Users\Administrator\AppData\Roaming\Python\Python310\Scripts"
# Write Python requirements file
New-Item python_packages.txt -Type File -Force -Value @"
black
certifi
click
colorama
fastapi[all]
flake8
isort
matplotlib
numpy
pandas
pillow
playwright
psutil
pygments
pytest
pyupgrade
requests
rich
ruff
selenium
speedtest-cli
tqdm
typer[all]
webdriver-manager
yt-dlp
"@
Invoke-CommandOrThrow python.exe -m pip install -r python_packages.txt
# Verify that Python packages are found
Update-Path
black --version

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
New-Item ~\.bashrc -Type File -Value @"
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
"@
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
gh auth login --web --hostname github.com --git-protocol https --scopes admin:public_key
gh ssh-key add "$SSH_KEY_PUB" --title "$env:computername"

Write-Host "Cloning repos..." -ForegroundColor "Yellow"
New-Item -Path ~\Developer -ItemType Directory
Set-Location -Path ~\Developer
git clone "https://github.com/Esgrove/AudioBatch"
git clone "https://github.com/Esgrove/Esgrove"
git clone "https://github.com/Esgrove/fastapi-template"
git clone "https://github.com/Esgrove/fdo_randomizer"
git clone "https://github.com/Esgrove/JUCE"
git clone "https://github.com/Esgrove/latex-template"
git clone "https://github.com/Esgrove/Oscilloscope"
git clone "https://github.com/Esgrove/othellogame"
git clone "https://github.com/Esgrove/playlist_formatter"
git clone "https://github.com/Esgrove/recordpool-dl"
git clone "https://github.com/Esgrove/rust-axum-example"
