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

try
{
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

  $areCommonScriptsLoaded = $false
  $commonScriptPath = "$env:USERPROFILE\My Documents\WindowsPowerShell\Common.ps1"
  if (Test-Path $commonScriptPath -PathType Leaf)
  {
    . $commonScriptPath
    $areCommonScriptsLoaded = $true
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

  if ($areCommonScriptsLoaded)
  {
    Write-Host 'Creating Alias "clw" as "Clear-Workspace"'
    Set-Alias clw Clear-Workspace -Option Constant
  }

  Write-Host 'Creating Alias "dirs" as "Get-Location -Stack"'
  Function BashDirs { Get-Location -Stack }
  Set-Alias dirs BashDirs -Option Constant

  $regexCmdletName = 'Run-RegexMatchLoop'
  $regexScriptName = 'Regex.ps1'
  $regexScriptPath = "$env:USERPROFILE\My Documents\WindowsPowerShell\$regexScriptName"
  . $regexScriptPath
  Write-Host "Creating Alias ""regex"" as cmdlet ""$regexCmdletName"""
  Set-Alias regex $regexCmdletName -Option Constant

  Write-Host 'Creating Alias "touch" as cmdlet "New-Item -Path {arg} -Type file"'
  Function BashTouch()
  {
    Param (
      [Parameter(
        Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $FilePath
    )

    New-Item -Path $FilePath -Type file
  }
  Set-Alias touch BashTouch -Option Constant

  Write-Host 'Creating Alias "which" as cmdlet "(Get-Command {arg}).Name"'
  Function BashWhich()
  {
    Param (
      [Parameter(
        Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $CommandName
    )

    $command = Get-Command $CommandName
    if ($command -ne $null)
    {
      return $command.Name
    }
  }
  Set-Alias which BashWhich -Option Constant

  # Cheap trick to determine if the NuGet PowerShell CLI is loaded in this shell
  $isNuGetCLILoaded = ![string]::IsNullOrEmpty((which Open-PackagePage 2> $null))
  if ($isNuGetCLILoaded)
  {
    Write-Host
    Write-Host 'NuGet Package Manager Console detected.'
    # TODO: add NuGet PowerShell shortcuts
  }

  Write-Host

  $vsCodeInstallLocation = Get-ProgramInstallLocation('Visual Studio Code')
  if (![string]::IsNullOrEmpty($vsCodeInstallLocation))
  {
    Write-Host 'Visual Studio Code is installed.'

    $vsCodePath = $vsCodeInstallLocation + 'Code.exe'
    if (Test-Path $vsCodePath -PathType Leaf)
    {
      Write-Host 'Creating Alias "code" as shortcut to VS Code'
      Set-Alias code $vsCodePath -Option Constant

      Write-Host 'Creating Alias "vscode" as shortcut to VS Code'
      Set-Alias vscode $vsCodePath -Option Constant
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

  if ($areCommonScriptsLoaded)
  {
    Pause-Script
  }

  $terminal.WindowTitle = "$initialTerminalWindowTitle - Profile Initialized"
}
catch
{
  $errorLogPath = "$env:USERPROFILE\My Documents\ProfileScriptErrors.log"
  if (!(Test-Path $errorLogPath -PathType Leaf))
  {
    New-Item -Path $errorLogPath -Type file -Force > $null
  }

  $_ >> $errorLogPath
}