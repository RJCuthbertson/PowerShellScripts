<#
  Common UX Functions:
    This file is for general purpose, utility functions intended to be
    used throughout the other scripts in this repository. Functions in
    this file handle display formatting and / or presentation, and are
    placed here to allow for a consistent UX across the other scripts
    in this repository.

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

Function Clear-Workspace()
{
  $cursorTop = [System.Console]::CursorTop
  if ($cursorTop)
  {
    [System.Console]::SetWindowPosition(0, $cursorTop)
  }
  else
  {
    Clear-Host
  }
}

Function Suspend-Script()
{
  # The PowerShell ISE detection was pulled from:
  # https://adamstech.wordpress.com/2011/05/12/how-to-properly-pause-a-powershell-script/
  if (!$psISE)
  {
    try
    {
      Write-Host -NoNewline 'Press any key to continue...'
      $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    catch [System.NotImplementedException]
    {
      # ReadKey throws an NIE when user interaction is not intended
    }
  }

  Write-Host
  Clear-Workspace
}