$ErrorActionPreference = 'Stop'

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$sourceFile = Join-Path $toolsDir 'nimv.bat'
$targetDir = "$($env:ChocolateyInstall)\bin"
$targetFile = Join-Path $targetDir 'nimv.bat'
$nixStyleTarget = Join-Path $targetDir 'nimv'

# Function to add Nimble to PATH
function Add-NimbleToPath {
    $NimbleBinPath = "$env:USERPROFILE\.nimble\bin"

    # Create the nimble bin directory if it doesn't exist
    if (-not (Test-Path $NimbleBinPath)) {
        New-Item -ItemType Directory -Path $NimbleBinPath -Force | Out-Null
        Write-Host "Created Nimble bin directory: $NimbleBinPath"
    }

    # Detect environment: PowerShell, CMD, or MSYS2
    $envType = "PowerShell"

    # Check if we're in MSYS2
    if ($env:MSYSTEM) {
        $envType = "MSYS2"
    }
    # Check if we're in cmd.exe (less reliable check)
    elseif ($Host.Name -eq "ConsoleHost" -and $PSVersionTable.PSEdition -eq $null) {
        $envType = "CMD"
    }

    switch ($envType) {
        "PowerShell" {
            # Check if PowerShell profile exists, create if not
            if (-not (Test-Path $PROFILE)) {
                New-Item -Type File -Path $PROFILE -Force | Out-Null
                Write-Host "Created PowerShell profile: $PROFILE"
            }

            # Check if path is already in profile
            $profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
            if ($profileContent -notmatch [regex]::Escape($NimbleBinPath)) {
                Add-Content -Path $PROFILE -Value "`n# Add Nimble to PATH`n`$env:PATH = `"$NimbleBinPath;`$env:PATH`""
                Write-Host "Added Nimble to PATH in PowerShell profile: $PROFILE"
            } else {
                Write-Host "Nimble PATH already configured in PowerShell profile"
            }

            $configFile = $PROFILE
            $activateCmd = ". $PROFILE"
        }

        "CMD" {
            # For CMD, we'll modify the user environment variable directly
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($currentPath -notmatch [regex]::Escape($NimbleBinPath)) {
                [Environment]::SetEnvironmentVariable("PATH", "$NimbleBinPath;$currentPath", "User")
                Write-Host "Added Nimble to User PATH environment variable"
            } else {
                Write-Host "Nimble PATH already configured in User environment variables"
            }

            $configFile = "User Environment Variables"
            $activateCmd = "Please restart your Command Prompt"
        }

        "MSYS2" {
            # For MSYS2, add to .bash_profile
            $bashProfile = "$env:USERPROFILE\.bash_profile"
            if (-not (Test-Path $bashProfile)) {
                New-Item -Type File -Path $bashProfile -Force | Out-Null
                Write-Host "Created bash profile: $bashProfile"
            }

            $profileContent = Get-Content $bashProfile -ErrorAction SilentlyContinue
            if ($profileContent -notmatch [regex]::Escape($NimbleBinPath)) {
                # Convert Windows path to Unix-style path for MSYS2
                $unixPath = $NimbleBinPath -replace '\\', '/' -replace '^(\w):', '/\L$1'
                Add-Content -Path $bashProfile -Value "`n# Add Nimble to PATH`nexport PATH=`"$unixPath:`$PATH`""
                Write-Host "Added Nimble to PATH in bash profile: $bashProfile"
            } else {
                Write-Host "Nimble PATH already configured in bash profile"
            }

            $configFile = $bashProfile
            $activateCmd = "source $bashProfile"
        }
    }

    Write-Host "----------------------------------------------------------------"
    Write-Host "Nimble bin directory ($NimbleBinPath) has been created and"
    Write-Host "added to PATH in your environment configuration."
    Write-Host ""
    Write-Host "To activate this change in your current session, run:"
    Write-Host "    $activateCmd"
    Write-Host ""
    Write-Host "Alternatively, you can start a new terminal session."
    Write-Host "----------------------------------------------------------------"
}

try {
    Write-Host "Installing nimv from $sourceFile to $targetFile"

    if (!(Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force
    }

    # Install the batch file
    Copy-Item -Path $sourceFile -Destination $targetFile -Force

    # Create a shell script wrapper for MSYS2/Unix environments
    $shellScript = @"
#!/bin/sh
exec nimv.bat `"`$@`"
"@

    $shellScript | Out-File -FilePath $nixStyleTarget -Encoding ASCII -NoNewline

    Add-NimbleToPath

    Write-Host "Nimv has been installed successfully to: $targetFile"
} catch {
    Write-Host "An error occurred during installation:"
    Write-Host $_
    throw
}