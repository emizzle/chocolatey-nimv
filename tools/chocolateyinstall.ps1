$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$fileLocation = Join-Path $toolsDir 'nimv.bat'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  fileType      = 'bat'
  file          = $fileLocation
  validExitCodes= @(0)
}

Install-ChocolateyInstallPackage @packageArgs
