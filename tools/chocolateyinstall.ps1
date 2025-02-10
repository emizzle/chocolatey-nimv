$ErrorActionPreference = 'Stop'

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$sourceFile = Join-Path $toolsDir 'nimv.bat'
$targetDir = "$($env:ChocolateyInstall)\bin"
$targetFile = Join-Path $targetDir 'nimv.bat'

try {
    Write-Host "Installing nimv from $sourceFile to $targetFile"

    if (!(Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force
    }

    Copy-Item -Path $sourceFile -Destination $targetFile -Force

    Write-Host "Nimv has been installed successfully to: $targetFile"
} catch {
    Write-Host "An error occurred during installation:"
    Write-Host $_
    throw
}