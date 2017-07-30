<#
  PowerShell Profile Initialization:
    This script is a work in progress to set up new PowerShell
    terminal sessions with functionality that I find useful.

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

Function Get-ProgramInstallLocation($programName)
{
  $thirtyTwoBitInstalls = `
    Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' |`
    Select-Object DisplayName, InstallLocation

  $sixtyFourBitInstalls = `
  Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' |`
    Select-Object DisplayName, InstallLocation

  $allInstalls = $thirtyTwoBitInstalls + $sixtyFourBitInstalls

  ForEach ($install in $allInstalls)
  {
    if (![string]::IsNullOrEmpty($install.DisplayName))
    {
      $name = $install.DisplayName
      if ($name.Contains($programName))
      {
        return $install.InstallLocation
      }
    }
  }
}

$terminal = $Host.UI.RawUI

$initialTerminalWindowTitle = $terminal.WindowTitle
$terminal.WindowTitle = "$initialTerminalWindowTitle - Profile Initializing..."

$terminal.BackgroundColor = 'Black'
$terminal.ForegroundColor = 'Green'

Write-Host
Write-Host ' PowerShell Profile Initialization'
Write-Host 'Copyright (C) 2017 - RJ Cuthbertson'
Write-Host '-----------------------------------'

Write-Host 'Removing Alias "curl"'
Remove-Item alias:curl

Write-Host 'Creating Alias "dirs" as "Get-Location -Stack"'
Function BashDirs { Get-Location -Stack }
Set-Alias dirs BashDirs -Option Constant

$regexCmdletName = 'Run-RegexMatchLoop'
$regexScriptName = 'Regex.ps1'
$regexScriptPath = "$env:USERPROFILE\My Documents\WindowsPowerShell\$regexScriptName"
. $regexScriptPath
Write-Host "Creating Alias ""regex"" as cmdlet ""$regexCmdletName"""
Set-Alias regex $regexCmdletName

Write-Host

$vsCodeInstallLocation = Get-ProgramInstallLocation('Visual Studio Code')
if (![string]::IsNullOrEmpty($vsCodeInstallLocation))
{
  Write-Host 'Visual Studio Code is installed.'

  $vsCodePath = $vsCodeInstallLocation + 'Code.exe'
  if (Test-Path $vsCodePath -PathType Leaf)
  {
    Write-Host 'Creating Alias "code" as shortcut to VS Code'
    Set-Alias code $vsCodePath

    Write-Host 'Creating Alias "vscode" as shortcut to VS Code'
    Set-Alias vscode $vsCodePath
  }
  else
  {
    Write-Host 'Visual Studio Code is installed, but the executable path could not be resolved.'
  }
}
else
{
  Write-Host 'Visual Studio Code is not installed.'
}

Write-Host

# TODO: consider moving this "clean press any key" to a shared function; Common.ps1? Utility.ps1?
Write-Host
Write-Host -NoNewline 'Press any key to continue...'
$x = $terminal.ReadKey('NoEcho,IncludeKeyDown')
Clear-Host

$terminal.WindowTitle = "$initialTerminalWindowTitle - Profile Initialized"