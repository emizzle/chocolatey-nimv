$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$sourceFile = Join-Path $toolsDir 'nimv.bat'
$targetDir = "$($env:ChocolateyInstall)\bin"
$targetFile = Join-Path $targetDir 'nimv.bat'
$nixStyleTarget = Join-Path $targetDir 'nimv'
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
    Write-Host "Nimv has been installed successfully to: $targetFile"

    # Add Nimble to PATH configuration (PowerShell only)
    $NimbleBinPath = "$env:USERPROFILE\.nimble\bin"

    # Create the nimble bin directory if it doesn't exist
    if (-not (Test-Path $NimbleBinPath)) {
        New-Item -ItemType Directory -Path $NimbleBinPath -Force | Out-Null
        Write-Host "Created Nimble bin directory: $NimbleBinPath"
    }

    # Modify user PATH environment variable
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notmatch [regex]::Escape($NimbleBinPath)) {
        [Environment]::SetEnvironmentVariable("PATH", "$NimbleBinPath;$currentPath", "User")
        Write-Host "Added Nimble to User PATH environment variable"
    } else {
        Write-Host "Nimble PATH already configured in User environment variables"
    }

    # PowerShell profile configuration
    if (-not (Test-Path $PROFILE)) {
        $profileDir = Split-Path -Parent $PROFILE
        if (-not (Test-Path $profileDir)) {
            New-Item -Type Directory -Path $profileDir -Force | Out-Null
        }
        New-Item -Type File -Path $PROFILE -Force | Out-Null
        Write-Host "Created PowerShell profile: $PROFILE"
    }

    $profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
    if ($profileContent -notmatch [regex]::Escape($NimbleBinPath)) {
        Add-Content -Path $PROFILE -Value "`n# Add Nimble to PATH`n`$env:PATH = `"$NimbleBinPath;`$env:PATH`""
        Write-Host "Added Nimble to PATH in PowerShell profile: $PROFILE"
    } else {
        Write-Host "Nimble PATH already configured in PowerShell profile"
    }

    # Simple completion message without detailed instructions
    Write-Host "Nimble bin directory ($NimbleBinPath) has been created and added to PATH"

} catch {
    Write-Host "An error occurred during installation:"
    Write-Host $_
    throw
}