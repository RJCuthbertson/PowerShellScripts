<#
  Self Elevating Script Template:
    This script template shows how to detect if a script has been
    invoked with administrator permissions, and elevates its
    execution to what is essentially "Run as Administrator" if not.

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

$currentUser = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (!($currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))
{
  Write-Host "This script (""$($MyInvocation.MyCommand)"") requires being run as an Administrator."
  Write-Host 'The execution privileges will now be elevated.'
  Write-Host

  Start-Process powershell "-NoExit -File ""$MyInvocation.MyCommand.Path""" -Verb RunAs -Wait
  return
}

# Script contents go here