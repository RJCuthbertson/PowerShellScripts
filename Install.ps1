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

Function Install-File()
{
  Param (
    [Parameter(
      Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $FileName,

    [Parameter(
      Mandatory=$false,
      ValueFromPipelineByPropertyName=$true)]
    [string]
    $CopyMessage = $null,

    [Parameter(
      Mandatory=$false,
      ValueFromPipelineByPropertyName=$true)]
    [string]
    $OverwriteMessage = $null,

    [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [bool]
    $AllowOverwrite = $true
  )

  if ([string]::IsNullOrEmpty($CopyMessage))
  {
    $CopyMessage = "Copying File ""$FileName"""
  }

  if ([string]::IsNullOrEmpty($OverwriteMessage))
  {
    $OverwriteMessage = "Overwriting File ""$FileName"""
  }

  $filePath = "$env:USERPROFILE\My Documents\WindowsPowerShell\$FileName"
  if (!(Test-Path $filePath -PathType Leaf))
  {
    Write-Host $CopyMessage
    New-Item -Path $FilePath -Type file -Force > $null
    Get-Content ".\$FileName" > $filePath
    Write-Host
  }
  else
  {
    Write-Host "File ""$FileName"" already exists."
    Write-Host

    if ($AllowOverwrite)
    {
      $overwrite = Read-Host "Overwrite? Yes (Y), or No (N)"
      while ($overwrite -ine 'Y' -and $overwrite -ine 'N')
      {
        Write-Host "Invalid Input ($overwrite)..."
        Write-Host
        $overwrite = Read-Host 'Overwrite? Yes (Y), or No (N)'
        Write-Host
      }

      if ($overwrite -ieq 'Y')
      {
        Write-Host $OverwriteMessage
        New-Item -Path $filePath -Type file -Force > $null
        Get-Content ".\$FileName" > $filePath
      }

      Write-Host
    }
  }
}

Write-Host

Install-File 'profile.ps1'`
  -CopyMessage 'Copying Profile Initialization Script'`
  -OverwriteMessage 'Overwriting Profile Initialization Script'
Install-File 'Common.ps1'
Install-File 'Regex.ps1'

Install-File 'DefaultWordlist.txt'`
  -CopyMessage 'Copying Default Wordlist'`
  -AllowOverwrite $false
Install-File 'LICENSE'`
  -CopyMessage 'Copying GNU General Public License'`
  -AllowOverwrite $false

if (Test-Path $commonScriptPath -PathType Leaf)
{
  . $commonScriptPath
  Pause-Script
}