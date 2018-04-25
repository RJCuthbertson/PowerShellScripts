<#
  Common:
    This file contains common functions that may be used in other
    scripts in this repository. It is also loaded by the user profile
    script, and therefore makes these functions available during
    an interactive PS session.

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

Function Get-CommandFullyQualifiedName()
{
  <#
    .SYNOPSIS
      A simple function to generate a command's fully qualified name.
    .DESCRIPTION
      This is a simple function to generate a command's fully qualified name.
      This is necessary to use when there is a naming conflict (multiple
      commands with the same name), and you need to specify which of the
      conflicting commands you intend to run, like when using proxy commands.
    .EXAMPLE
      Get-CommandFullyQualifiedName New-Object
      Gets the fully qualified name of the New-Object cmdlet
    .NOTES
      Copyright (C) 2017  RJ Cuthbertson
  #>

  [OutputType([string])]
  Param (
    [Parameter(
      Mandatory = $true,
      Position = 0,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CommandName
  )

  $command = Get-Command -Name $CommandName
  if (![string]::IsNullOrEmpty($command.ModuleName))
  {
    return Join-Path -Path $command.ModuleName -ChildPath $command.Name
  }

  if ($command.CommandType -ieq 'Application')
  {
    return $command.Definition
  }

  return $command.Name
}

Function Get-ExecutionPath()
{
  <#
    .SYNOPSIS
      Gets the current path of the currently executing context.
    .DESCRIPTION
      This function gets the current path of the currently executing context.
      It returns the base path from "$script:MyInvocation.MyCommand".
    .EXAMPLE
      Get-ExecutionPath
      Returns the current path of the currently executing context.
    .NOTES
      Copyright (C) 2018  RJ Cuthbertson
  #>

  return Split-Path $script:MyInvocation.MyCommand.Path
}

Function Get-NormalizedFilePath()
{
  <#
    .SYNOPSIS
      Gets the full path of the provided file or folder if it exists.
      Otherwise, false is returned.
    .DESCRIPTION
      Gets the full path of the provided file or folder if it exists.
      It can be used to get an absolute path from a relative path, and / or
      to validate the existence of a given file or folder. If the path is not
      valid, a false value is returned.
    .EXAMPLE
      Get-NormalizedFilePath .\path\to\file.ext
      Gets the full path of the provided file or folder if it exists.
      Otherwise, returns false.
    .NOTES
      Copyright (C) 2018  RJ Cuthbertson
  #>

  Param(
    [Parameter(
      Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $FilePath
  )

  $testPath = $FilePath
  if (![System.IO.Path]::IsPathRooted($FilePath))
  {
    $testPath = Join-Path (Get-Location) $FilePath
  }

  try
  {
    $fullPath = [System.IO.Path]::GetFullPath($testPath)
    if ([System.IO.File]::Exists($fullPath) -or [System.IO.Directory]::Exists($fullPath))
    {
      return $fullPath
    }
  }
  catch
  {
  }

  return $false
}

Function Get-ProgramInstallLocation()
{
  <#
    .SYNOPSIS
      Searches the registry to determine the location of the program installer.
    .DESCRIPTION
      This function searches the registry installer data (for both 32 and 64 bit
      applications if applicable) and returns the location of the installer for the
      first program install that contains the provided program name.

      NOTE: This function uses a partial match of the provided program name. If there
      are multiple programs installed with the provided string in their display name,
      only the first installer location will be returned.
    .EXAMPLE
      Get-ProgramInstallLocation 'Visual Studio Code'
      Returns the location of the installer file for Visual Studio Code if installed.
    .NOTES
      Copyright (C) 2017  RJ Cuthbertson
  #>

  Param (
    [Parameter(
      Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ProgramName
  )

  $thirtyTwoBitInstalls = `
    Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' |`
    Select-Object DisplayName, InstallLocation

  $allInstalls = $thirtyTwoBitInstalls
  if ([Environment]::Is64BitOperatingSystem)
  {
    $sixtyFourBitInstalls = `
    Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' |`
      Select-Object DisplayName, InstallLocation

    $allInstalls = $thirtyTwoBitInstalls + $sixtyFourBitInstalls
  }

  ForEach ($install in $allInstalls)
  {
    if (![string]::IsNullOrEmpty($install.DisplayName))
    {
      $name = $install.DisplayName
      if ($name.Contains($ProgramName))
      {
        return $install.InstallLocation
      }
    }
  }
}

Function Get-RegistryKeyValue()
{
  <#
    .SYNOPSIS
      Gets the specified registry key value if it exists.
    .DESCRIPTION
      Gets the specified registry key value if it exists.
    .EXAMPLE
      Get-RegistryKeyValue 'HKCU:\SomeRegistryKey\Path'
      Gets the default value of the registry key at HKEY_CURRENT_USER > SomeRegistryKey > Path
    .EXAMPLE
      Get-RegistryKeyValue 'HKCU:\SomeRegistryKey\Path' -PropertyName 'Prop'
      Gets the value of the 'Prop' property of the registry key at HKEY_CURRENT_USER > SomeRegistryKey > Path
    .NOTES
      Copyright (C) 2017  RJ Cuthbertson
  #>

  Param (
    [Parameter(
      Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RegistryKey,

    [Parameter(
      Mandatory=$false,
      ValueFromPipelineByPropertyName=$true)]
    [string]
    $PropertyName
  )

  if ($PropertyName)
  {
    return Get-ItemPropertyValue -LiteralPath $RegistryKey -Name $PropertyName
  }
  else
  {
    return (Get-ItemProperty -LiteralPath $RegistryKey).'(Default)'
  }
}

Function Invoke-DosCommand()
{
  <#
    .SYNOPSIS
      This function silently executes a given DOS command, so long as 'cmd' is available.
    .DESCRIPTION
      This function silently executes a given DOS command, so long as 'cmd' is available.
      The command prompt is not available from the PowerShell ISE, and will throw an
      exception if an attempt to use this from within ISE is made.
    .EXAMPLE
      Invoke-DosCommand 'rd "%HomeDrive%\SomeFolder" /Q /S'
      Deletes the directory 'C:\SomeFolder' if C:\ is the system Home Drive.
    .NOTES
      Copyright (C) 2017  RJ Cuthbertson
  #>

  Param (
    [Parameter(
      Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Command
  )

  if (!($psISE))
  {
    cmd /c $Command | Out-Null
  }
  else
  {
    throw 'The command prompt is not available in the PowerShell ISE.'
  }
}

Function New-ProxyCommand
{
  <#
    .SYNOPSIS
      A simple function to generate new proxy commands.
    .DESCRIPTION
      This is a simple function to generate the shell of new proxy commands,
      rather than having to type out the long form of the commands to create a new
      System.Management.Automation.CommandMetaData object, and then passing it to
      the static method System.Management.Automation.ProxyCommand.Create().
    .EXAMPLE
      New-ProxyCommand New-Object
      Creates a new proxy command wrapping the New-Object cmdlet
    .NOTES
      Copyright (C) 2017  RJ Cuthbertson
  #>

  Param (
    [Parameter(
      Mandatory = $true,
      Position = 0,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CommandName
  )

  $commandMetaData = New-Object System.Management.Automation.CommandMetaData (Get-Command $CommandName)
  [System.Management.Automation.ProxyCommand]::Create($commandMetaData)
}

Function Remove-RegistryKey()
{
  <#
    .SYNOPSIS
      Removes the specified registry key if it exists.
    .DESCRIPTION
      Removes the specified registry key if it exists.
    .EXAMPLE
      Remove-RegistryKey 'HKCU:\SomeRegistryKey\Path'
      Removes the registry key at HKEY_CURRENT_USER > SomeRegistryKey > Path
    .NOTES
      Copyright (C) 2017  RJ Cuthbertson
  #>

  Param (
    [Parameter(
      Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RegistryPath
  )

  if (Test-Path -LiteralPath $RegistryPath)
  {
    Remove-Item -LiteralPath $RegistryPath -Recurse -Force 2> $null
  }
}

Function Remove-RegistryKeyValue()
{
  <#
    .SYNOPSIS
      Removes the specified registry key property if it exists.
    .DESCRIPTION
      Removes the specified registry key property if it exists.
    .EXAMPLE
      Remove-RegistryKeyValue -RegistryPath 'HKCU:\SomeRegistryKey\Path' -PropertyName 'Prop'
      Removes the 'Prop' property from the registry key at HKEY_CURRENT_USER > SomeRegistryKey > Path
    .NOTES
      Copyright (C) 2017  RJ Cuthbertson
  #>

  Param (
    [Parameter(
      Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RegistryPath,

    [Parameter(
      Mandatory=$true,
      ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $PropertyName
  )

  if (Test-Path -LiteralPath $RegistryPath)
  {
    Remove-ItemProperty -LiteralPath $RegistryPath -Name $PropertyName -Force 2> $null
  }
}

Function Reset-SessionProfile()
{
  <#
    .SYNOPSIS
      A simple function to reload the profile in the current session.
    .DESCRIPTION
      This function reloads the user profile in the current PowerShell
      terminal session without requiring the user to exit the terminal
      instance and open a new one in order to take advantage of
      modifications that have been made to the user profile since opening
      the working terminal instance.
    .EXAMPLE
      Reset-SessionProfile
      Reloads the user profile in the current terminal session
    .NOTES
      Copyright (C) 2017  RJ Cuthbertson
  #>

  Function Reset-ProfileIfExists($filePath)
  {
    if (Test-Path $filePath -PathType Leaf)
    {
      . $filePath
    }
  }

  $PROFILE | Get-Member -MemberType NoteProperty | Select-Object Name | `
    ForEach-Object { Reset-ProfileIfExists $PROFILE.($_.Name) }
}

Function Set-RegistryKeyValue()
{
  <#
    .SYNOPSIS
      Sets the provided value to the specified registry key's property.
    .DESCRIPTION
      Sets the provided value to the specified registry key's property.
      If this key does not exist, it is created.
      If a property name is not provided, the default value (of type 'String' / 'REG_SZ') is set.
      If a property name is provided, but the property type is not, the 'DWORD' type is assumed.
    .EXAMPLE
      Set-RegistryKeyValue -RegistryPath 'HKCU:\SomeRegistryKey\Path' -Value 'Value'
      Sets the default value of the registry key at HKEY_CURRENT_USER > SomeRegistryKey > Path to the value 'Value'
    .EXAMPLE
      Set-RegistryKeyValue -RegistryPath 'HKCU:\SomeRegistryKey\Path' -PropertyName 'Prop' -Value '0'
      Sets the property 'Prop' of the registry key at HKEY_CURRENT_USER > SomeRegistryKey > Path to the value '0'
    .EXAMPLE
      Set-RegistryKeyValue -RegistryPath 'HKCU:\SomeRegistryKey\Path' -PropertyName 'Prop' -Value 'Value' -PropertyType 'String'
      Sets the property 'Prop' of the registry key at HKEY_CURRENT_USER > SomeRegistryKey > Path to the value 'Value' of type 'String' (REG_SZ)
    .NOTES
      Copyright (C) 2017  RJ Cuthbertson
  #>

  Param (
    [Parameter(
      Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RegistryPath,

    [Parameter(
      Mandatory=$false,
      ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $PropertyName = '(Default)',

    [Parameter(
      Mandatory=$false,
      ValueFromPipelineByPropertyName=$true)]
    [string]
    $Value,

    [Parameter(
      Mandatory=$false,
      ValueFromPipelineByPropertyName=$true)]
    [ValidateSet('Binary', 'DWord', 'ExpandString', 'MultiString', 'String', 'QWord')]
    [string]
    $PropertyType = 'DWord'
  )

  if (!(Test-Path -LiteralPath $RegistryPath))
  {
    New-Item -Path $RegistryPath -Force > $null
  }

  if ($Value)
  {
    if ($PropertyName -eq '(Default)')
    {
      New-Item -Path $RegistryPath -Value $Value -Force > $null
    }
    else
    {
      New-ItemProperty -LiteralPath $RegistryPath -Name $PropertyName -Value $Value `
        -PropertyType $PropertyType -Force > $null
    }
  }
  else
  {
    New-ItemProperty -LiteralPath $RegistryPath -Name $PropertyName -PropertyType $PropertyType -Force > $null
  }
}