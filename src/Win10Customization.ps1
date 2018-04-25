<#
  Windows 10 Customizations:
    This script automates some of the tasks related to customization
    of Windows 10 that I've found myself performing multiple times.
    It will automatically elevate itself to be run as an administrator
    if it is invoked without this level of access.

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

# Self Elevating Security Invocation
$currentUser = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (!($currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))
{
  Write-Host "This script (""$($MyInvocation.MyCommand)"") requires being run as an Administrator."
  Write-Host 'The execution privileges will now be elevated.'
  Write-Host

  Start-Process powershell "-NoExit -File ""$MyInvocation.MyCommand.Path""" -Verb RunAs -Wait
  return
}

#region Load Common.ps1
$profilePath = $PROFILE.CurrentUserAllHosts
$profileBaseDirectory = $profilePath.Substring(0, $profilePath.LastIndexOf('\'))
$commonScriptPath = "$profileBaseDirectory\Common.ps1"
if (Test-Path $commonScriptPath -PathType Leaf)
{
  . $commonScriptPath
}
else
{
  Write-Host "Missing required file: $commonScriptPath"
  return
}
#endregion

#region Ensure HKCR PSProvider
if (!(Test-Path -Path 'HKCR:\'))
{
  Write-Host 'HKEY_CLASSES_ROOT is not available to PowerShell - creating New-PSDrive HKCR:\'
  New-PSDrive -Name 'HKCR' -PSProvider 'Registry' -Root 'HKEY_CLASSES_ROOT' > $null

  if (Test-Path -Path 'HKCR:\')
  {
    Write-Host 'HKCR:\ created successfully'
  }
  else
  {
    Write-Error 'HKCR:\ could not be correctly created.'
    return
  }
}
#endregion

#region Customize Context Menu
Write-Host 'Cleaning up some context menu items (right click)'
Remove-RegistryKey 'HKCR:\*\OpenWithList\Excel.exe'
Remove-RegistryKey 'HKCR:\*\OpenWithList\Winword.exe'
Remove-RegistryKey 'HKCR:\*\OpenWithList\WordPad.exe'

Remove-RegistryKey 'HKCR:\*\shellex\ContextMenuHandlers\BriefcaseMenu'
# EPP = Scan with Windows Defender
Remove-RegistryKey 'HKCR:\*\shellex\ContextMenuHandlers\EPP'
Remove-RegistryKey 'HKCR:\*\shellex\ContextMenuHandlers\Sharing'
Remove-RegistryKey 'HKCR:\*\shellex\ContextMenuHandlers\WorkFolders'

Write-Host 'Ensuring .ps1 script files offer "Run as Administrator" option in context menu'
Set-RegistryKeyValue -RegistryPath 'HKCR:\Microsoft.PowerShellScript.1\Shell\runas' -PropertyName 'HasLUAShield'

Set-RegistryKeyValue -RegistryPath 'HKCR:\Microsoft.PowerShellScript.1\Shell\runas\command' `
  -Value 'powershell "-Command" "if((Get-ExecutionPolicy ) -ne ''AllSigned'') { Set-ExecutionPolicy -Scope Process Bypass }; & ''%1''"'

try
{
  # Visual Studio Code overrides the default context menu handler for a multitude of file types to "VSCode.{ext}"...
  if (Test-Path 'HKCR:\.ps1\OpenWithProgids' -and Get-RegistryKeyValue 'HKCR:\.ps1\OpenWithProgids' -PropertyName 'VSCode.ps1')
  {
    Set-RegistryKeyValue -RegistryPath 'HKCR:\VSCode.ps1\Shell\runas' -PropertyName 'HasLUAShield'

    Set-RegistryKeyValue -RegistryPath 'HKCR:\VSCode.ps1\Shell\runas\command' `
      -Value 'powershell "-Command" "if((Get-ExecutionPolicy) -ne ''AllSigned'') { Set-ExecutionPolicy -Scope Process Bypass }; & ''%1''"'
  }
}
catch
{
  # Get-RegistryKeyValue may throw an exception if property does not exist
}
#endregion

Write-Host 'Hiding "People" icon in taskbar'
Set-RegistryKeyValue -RegistryPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People' `
  -PropertyName 'PeopleBamd' -Value '0'

#region Customize Explorer Navigation Pane
Write-Host 'Setting default behavior of "Open File Explorer to:" setting in Folder Options as "This PC"'
Set-RegistryKeyValue -RegistryPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
  -PropertyName 'LaunchTo' -Value '1'

Write-Host 'Setting "Show all Folders" navigation pane setting to off'
Set-RegistryKeyValue -RegistryPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
  -PropertyName 'NavPaneShowAllFolders' -Value '0'

Write-Host 'Removing Quick Access from Explorer navigation pane'
Set-RegistryKeyValue -RegistryPath 'HKCR:\CLSID\{679f85cb-0220-4080-b29b-5540cc05aab6}\ShellFolder' `
  -PropertyName 'Attributes' -Value 'a0600000'

if ([Environment]::Is64BitOperatingSystem)
{
  Set-RegistryKeyValue -RegistryPath 'HKCR:\Wow6432Node\CLSID\{679f85cb-0220-4080-b29b-5540cc05aab6}\ShellFolder' `
    -PropertyName 'Attributes' -Value 'a0600000'
}

Write-Host 'Removing duplicate Removable Drive icons from navigation pane'
Remove-RegistryKey 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}'

if ([Environment]::Is64BitOperatingSystem)
{
  Remove-RegistryKey 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}'
}
#endregion

#region Remove Telemetry
if (Get-Command which 2> $null)
{
  if (which dotnet)
  {
    Write-Host 'Opting out of DotNet CLI Telemetry'
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
  }
}
#endregion

#region Remove OneDrive
if (Get-ProgramInstallLocation 'OneDrive.exe')
{
  if (Get-Process -Name 'OneDrive')
  {
    Write-Host 'Ending presently running OneDrive instance'
    Stop-Process -Name 'OneDrive' -Force
  }

  Write-Host 'Uninstalling OneDrive'
  if ([Environment]::Is64BitOperatingSystem)
  {
    if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe")
    {
      Invoke-DosCommand "%SystemRoot%\SysWOW64\OneDriveSetup.exe /uninstall"
    }
  }
  else
  {
    if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe")
    {
      Invoke-DosCommand "%SystemRoot%\System32\OneDriveSetup.exe /uninstall"
    }
  }
}

Write-Host 'Deleting OneDrive data'
if (Test-Path "$env:USERPROFILE\OneDrive")
{
  Invoke-DosCommand 'rd "%UserProfile%\OneDrive" /Q /S'
}

if (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive")
{
  Invoke-DosCommand 'rd "%LocalAppData%\Microsoft\OneDrive" /Q /S'
}

if (Test-Path "$env:ProgramData\Microsoft OneDrive")
{
  Invoke-DosCommand 'rd "%ProgramData%\Microsoft OneDrive" /Q /S'
}

if (Test-Path "$env:HOMEDRIVE\OneDriveTemp")
{
  Invoke-DosCommand 'rd "%HomeDrive%\OneDriveTemp" /Q /S'
}

Write-Host 'Removing OneDrive links and registry entries from the system'

Remove-RegistryKey 'HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
if ([Environment]::Is64BitOperatingSystem)
{
  Remove-RegistryKey 'HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
}
Remove-RegistryKey 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
#endregion
