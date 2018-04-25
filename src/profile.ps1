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

$profilePath = $PROFILE.CurrentUserAllHosts
$profileBaseDirectory = $profilePath.Substring(0, $profilePath.LastIndexOf('\'))

$areCommonScriptsLoaded = $false
$commonScriptPath = "$profileBaseDirectory\Common.ps1"
if (Test-Path $commonScriptPath -PathType Leaf)
{
  . $commonScriptPath
  $areCommonScriptsLoaded = $true
}

$areCommonUxScriptsLoaded = $false
$commonUxScriptPath = "$profileBaseDirectory\CommonUX.ps1"
if (Test-Path $commonUxScriptPath -PathType Leaf)
{
  . $commonUxScriptPath
  $areCommonUxScriptsLoaded = $true
}

try
{
  $terminal = $Host.UI.RawUI

  $initialTerminalWindowTitle = $terminal.WindowTitle
  $terminal.WindowTitle = "$initialTerminalWindowTitle - Profile Initializing..."

  $terminal.BackgroundColor = 'Black'
  $terminal.ForegroundColor = 'Green'

  if ($Host.Version.Major -ge 5)
  {
    Set-PSReadlineOption -ResetTokenColors
    Clear-Host
  }

  Write-Host
  Write-Host ' PowerShell Profile Initialization'
  Write-Host 'Copyright (C) 2017 - RJ Cuthbertson'
  Write-Host '-----------------------------------'

  if (Get-Command curl 2> $null)
  {
    Write-Host 'Removing Alias "curl"'
    Remove-Item alias:curl
  }

  if ($areCommonUxScriptsLoaded)
  {
    Write-Host 'Creating Alias "clw" as "Clear-Workspace"'
    Set-Alias clw Clear-Workspace -Option Constant
  }

  Write-Host 'Creating Alias "dirs" as "Get-Location -Stack"'
  Function BashDirs { Get-Location -Stack }
  Set-Alias dirs BashDirs -Option Constant

  Write-Host 'Creating Alias "findf" as recursive file search on all file systems'
  Function Find-File()
  {
    Param (
      [Parameter(
        Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $FileFilter
    )

    Get-PSDrive -PSProvider 'FileSystem' | `
      Where-Object { Get-Volume -DriveLetter $_.Name } | `
      Where-Object { $_.OperationalStatus -eq 'OK' } | `
      Where-Object { Get-ChildItem -Path "$($_.DriveLetter):\" -Filter $FileFilter -Recurse -Force 2> $null | Where-Object { $_.FullName } }
  }
  Set-Alias findf Find-File -Option Constant

  $regexCmdletName = 'Run-RegexMatchLoop'
  $regexScriptName = 'Regex.ps1'
  $regexScriptPath = "$profileBaseDirectory\$regexScriptName"
  Write-Host "Adding cmdlet ""$regexCmdletName"""
  . $regexScriptPath
  Write-Host "Creating Alias ""regex"" as cmdlet ""$regexCmdletName"""
  Set-Alias regex $regexCmdletName -Option Constant

  Write-Host 'Creating Alias "touch" as "New-Item -Path {arg} -Type file"'
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

  if ($areCommonScriptsLoaded)
  {
    Write-Host 'Creating Alias "unzip" as .zip archive extraction method'
    Function Expand-ZipArchive()
    {
      Param(
        [Parameter(
          Mandatory=$true,
          Position=0,
          ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Source,

        [Parameter(
          Mandatory=$false,
          Position=1,
          ValueFromPipeline=$true)]
        [string]
        $Target
      )

      $fileSystemCompressionAssembly = [AppDomain]::CurrentDomain.GetAssemblies() | `
        Where-Object { $_.FullName.StartsWith("System.IO.Compression.FileSystem,") }

      if (!$fileSystemCompressionAssembly)
      {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
      }

      if ([string]::IsNullOrEmpty($Target))
      {
        $normalizedTarget = Get-Location
      }
      else
      {
        $normalizedTarget = Get-NormalizedFilePath $Target
      }

      $normalizedSource = Get-NormalizedFilePath $Source

      [System.IO.Compression.ZipFile]::ExtractToDirectory($normalizedSource, $normalizedTarget)
    }
    Set-Alias unzip Expand-ZipArchive -Option Constant
  }

  Write-Host 'Creating Alias "which" as use of cmdlet "Get-Command"'
  Function BashWhich()
  {
    Param (
      [Parameter(
        Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $CommandName,

      [Parameter(
        Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
      [Alias('a', 'all')]
      [switch]
      $GetAll
    )

    $results = Get-Command $CommandName 2> $null
    if ($results -eq $null)
    {
      return $null
    }

    if ($results.Count -eq 1)
    {
      return $results.Name
    }
    else
    {
      if ($GetAll)
      {
        $compoundResult = ''
        foreach ($result in $results)
        {
          $compoundResult = $compoundResult + "$($result.Source)\$($result.Name);"
        }

        return $compoundResult
      }

      $firstResult = $results[0]
      return "$($firstResult.Source)\$($firstResult.Name)"
    }
  }
  Set-Alias which BashWhich -Option Constant

  try
  {
    if (!((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -eq 'Enabled'))
    {
      Write-Host 'Enabling Windows Subsystem for Linux'
      Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
      Write-Host 'Windows Subsystem for Linux enabled'
    }
    else
    {
      Write-Host 'Windows Subsystem for Linux is enabled'
    }

    Write-Host
  }
  catch
  {
    Write-Host 'Can not detect or enable the Windows Subsystem for Linux'
  }

  if (!!(which kali))
  {
    Write-Host 'To install Kali, please visit https://www.microsoft.com/en-us/store/p/kali-linux/9pkr34tncv07'
    Write-Host
  }

  # Cheap trick to determine if the NuGet PowerShell CLI is loaded in this shell
  $isNuGetCLILoaded = !!(which Open-PackagePage)
  if ($isNuGetCLILoaded)
  {
    Write-Host
    Write-Host 'NuGet Package Manager Console detected.'
    # TODO: add NuGet PowerShell shortcuts
  }

  Write-Host

  if (!(Get-PackageProvider NuGet))
  {
    Write-Host 'Installing the NuGet package provider'
    Install-PackageProvider NuGet
    Import-PackageProvider NuGet
  }

  if (!(Get-PackageProvider PowerShellGet))
  {
    Write-Host 'Installing the PowerShellGet package provider'
    Install-PackageProvider PowerShellGet
    Import-PackageProvider PowerShellGet
  }

  if (which docker)
  {
    Write-Host 'Docker is installed.'

    if (!(Get-Module -ListAvailable -Name posh-docker))
    {
      Write-Host "Installing the posh-docker PS Module."
      Install-Module -Scope CurrentUser posh-docker
    }

    if (Get-Module -ListAvailable -Name posh-docker)
    {
      if (Get-Module -Name posh-docker)
      {
        Write-Host 'The Posh Docker Module has already been imported.'
      }
      else
      {
        Import-Module posh-docker
        Write-Host 'The Posh Docker Module has been imported.'
      }
    }
  }
  else
  {
    Write-Host 'Docker is not installed, or is not available to this shell.'
  }

  Write-Host

  if (which dotnet)
  {
    Write-Host 'The DotNet CLI is installed.'

    if (!(Get-Module -ListAvailable -Name posh-dotnet))
    {
      Write-Host "Installing the posh-dotnet PS Module."
      Install-Module -Scope CurrentUser posh-dotnet
    }

    if (Get-Module -ListAvailable -Name posh-dotnet)
    {
      if (Get-Module -Name posh-dotnet)
      {
        Write-Host 'The Posh DotNet Module has already been imported.'
      }
      else
      {
        Import-Module posh-dotnet
        Write-Host 'The Posh DotNet Module has been imported.'
      }
    }
  }
  else
  {
    Write-Host 'The DotNet CLI is not installed, or is not available to this shell.'
  }

  Write-Host

  if (which git)
  {
    Write-Host 'Git is installed.'

    if (!(Get-Module -ListAvailable -Name posh-git))
    {
      Write-Host "Installing the posh-git PS Module."
      Install-Module -Scope CurrentUser posh-git
    }

    if (Get-Module -ListAvailable -Name posh-git)
    {
      if (Get-Module -Name posh-git)
      {
        Write-Host 'The Posh Git Module has already been imported.'
      }
      else
      {
        Import-Module posh-git
        Write-Host 'The Posh Git Module has been imported.'
      }
    }
  }
  else
  {
    Write-Host 'Git is not installed, or is not available to this shell.'
  }

  Write-Host

  $vsCodeInstallLocation = Get-ProgramInstallLocation('Visual Studio Code')
  if (![string]::IsNullOrEmpty($vsCodeInstallLocation))
  {
    Write-Host 'Visual Studio Code is installed.'

    $vsCodePath = $vsCodeInstallLocation + 'Code.exe'
    if (Test-Path $vsCodePath -PathType Leaf)
    {
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
    Write-Host 'Visual Studio Code is not installed, or is not available to this shell.'
  }

  Write-Host

  $terminal.WindowTitle = "$initialTerminalWindowTitle - Profile Initialized"
}
catch
{
  if ($areCommonScriptsLoaded)
  {
    $executionPath = Get-ExecutionPath
    $errorLogPath = "$executionPath\ProfileScriptErrors.log"
    if (!(Test-Path $errorLogPath -PathType Leaf))
    {
      New-Item -Path $errorLogPath -Type file -Force > $null
    }

    $_ >> $errorLogPath
  }

  Write-Host $_.Exception
}