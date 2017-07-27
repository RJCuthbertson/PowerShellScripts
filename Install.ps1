<#
  PowerShell Scripts Installer:
    This is just an install script for the scripts in this repository
    and their dependencies.

  Copyright (C) 2017  RJ Cuthbertson

  This script can be found on GitHub:
    https://github.com/RJCuthbertson/PowerShellScripts

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

$doesProfileExist = Test-Path $PROFILE.CurrentUserAllHosts
if (!$doesProfileExist)
{
  Write-Host
  Write-Host 'Copying Profile Initialization Script'
  New-Item -Path $PROFILE.CurrentUserAllHosts -Type file -Force > $null
  Get-Content '.\profile.ps1' > $PROFILE.CurrentUserAllHosts
}
else
{
  Write-Host
  Write-Host 'A Profile Initialization Script already exists.'
  Write-Host 'Would you like to overwrite? Otherwise, the profile.ps1 contents will be appended to the existent file.'
  Write-Host
  $overwrite = Read-Host "Overwrite? Yes (Y), or No (N)"
  while ($overwrite -ine 'Y' -and $overwrite -ine 'N')
  {
    Write-Host "Invalid Input ($overwrite)..."
    Write-Host
    $overwrite = Read-Host 'Overwrite? Yes (Y), or No (N)'
  }

  if ($overwrite -ieq 'Y')
  {
    Write-Host
    Write-Host 'Overwriting Profile Initialization Script'
    New-Item -Path $PROFILE.CurrentUserAllHosts -Type file -Force > $null
    Get-Content '.\profile.ps1' > $PROFILE.CurrentUserAllHosts
  }
  else
  {
    Write-Host
    Write-Host 'Appending Profile Initialization Script to existent profile customizations'
    Get-Content '.\profile.ps1' >> $PROFILE.CurrentUserAllHosts
  }
}

$regexScriptName = 'Regex.ps1'
$regexScriptPath = "$env:USERPROFILE\My Documents\WindowsPowerShell\$regexScriptName"
if (!(Test-Path $regexScriptPath -PathType Leaf))
{
  Write-Host
  Write-Host "Copying Script ""$regexScriptName"""
  New-Item -Path $regexScriptPath -Type file -Force > $null
  Get-Content '.\Regex.ps1' > $regexScriptPath
}

$wordlistPath = "$env:USERPROFILE\My Documents\WindowsPowerShell\DefaultWordlist.txt"
if (!(Test-Path $wordlistPath -PathType Leaf))
{
  Write-Host
  Write-Host 'Copying Default Wordlist'
  New-Item -Path $wordlistPath -Type file -Force > $null
  Get-Content '.\DefaultWordlist.txt' > $wordlistPath
}

$licensePath = "$env:USERPROFILE\My Documents\WindowsPowerShell\LICENSE"
if (!(Test-Path $licensePath -PathType Leaf))
{
  Write-Host
  Write-Host 'Copying GNU General Public License'
  New-Item -Path $licensePath -Type file -Force > $null
  Get-Content '.\LICENSE' > $licensePath
}

Write-Host
Write-Host -NoNewline "Press any key to continue..."
$x = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Clear-Host