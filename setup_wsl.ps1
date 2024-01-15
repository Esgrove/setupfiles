# PowerShell script to copy files from Windows to WSL and execute setup script in WSL

# First install / update WSL before running this script:
# wsl --install
# wsl --update
# wsl --shutdown

# Run this script:
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser
# .\setup_wsl.ps1

# Get the directory of the current script
$scriptDirectory = $PSScriptRoot

# Define the source paths for the scripts on Windows
$setup_script = ($scriptDirectory -replace 'D:\\', '/mnt/d/').Replace('\', '/') + "/setup_wsl_ubuntu.sh"
$shell_profile = ($scriptDirectory -replace 'D:\\', '/mnt/d/').Replace('\', '/') + "/wsl_profile.sh"

Write-Host "Copying files to wsl..." -ForegroundColor "Yellow"
Write-Host "$setup_script"
Write-Host "$shell_profile"

# Copy the scripts to WSL
wsl cp "`"$setup_script`"" "~/"
wsl cp "`"$shell_profile`"" "~/"

# Run the setup script in WSL
wsl bash -c "chmod +x ~/setup_wsl_ubuntu.sh"
wsl bash -c "./setup_wsl_ubuntu.sh"
