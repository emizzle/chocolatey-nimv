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
} catch {
    Write-Host "An error occurred during installation:"
    Write-Host $_
    throw
}