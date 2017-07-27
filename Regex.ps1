<#
  Regex Match Loop:
    This script is a work in progress that loads a text document
    and find lines that are matched by Regular Expressions
    provided by the end user via an input loop in the terminal.

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

Function Run-RegexMatchLoop
{
  <#
  .SYNOPSIS
    An input loop that finds Regular Expressions matches of lines of a text document
  .DESCRIPTION
    This script is a work in progress that loads a text document
    and finds lines that are matched by Regular Expressions
    provided by the end user via an input loop in the terminal.
  .EXAMPLE
    .\Regex.ps1
    Provide no file path to load the default wordlist document to match the provided Regular Expressions against it.
  .EXAMPLE
    .\Regex.ps1 ".\TextDocument.txt"
    Loads the file in the provided path to match the provided Regular Expressions against it.
    The -FilePath flag is optional; the first parameter will map to the -FilePath flag.
  .EXAMPLE
    .\Regex.ps1 -FilePath ".\TextDocument.txt"
    Loads the file in the provided path to match the provided Regular Expressions against it.
  .PARAMETER FilePath
    The optional path to a text document to load as the target of matching the provided Regular Expressions against it.
  .NOTES
    Copyright (C) 2017  RJ Cuthbertson
  #>

  [CmdletBinding()]
  Param (
    [Parameter(Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [string]
    $FilePath

    # TODO: take regex processing options as flags
  )

  Function Exit-Script
  {
    Write-Host 'The script will now exit'
    Write-Host
  }

  Function Get-RegularExpression
  {
    return Read-Host 'Please enter a regular expression'
  }

  $defaultWordlistDocumentPath = "$env:USERPROFILE\My Documents\WindowsPowerShell\DefaultWordlist.txt"
  $lines = @()

  Write-Host

  if (![string]::IsNullOrEmpty($FilePath))
  {
    if (Test-Path $FilePath -PathType Leaf)
    {
      Write-Host "Trying to load text document at ""$FilePath""..."
      $lines = Get-Content $FilePath
    }
    else
    {
      Write-Host "No text document exists at $FilePath"
      return Exit-Script
    }
  }
  else
  {
    Write-Host "Trying to load default wordlist document..."
    $lines = Get-Content $defaultWordlistDocumentPath
  }

  Write-Host
  Write-Host "File loaded successfully. There are $($lines.Length) lines."
  Write-Host
  Write-Host 'You may now type regular expressions to run a match against the content of the file.'
  Write-Host 'To exit, type "EXIT"'
  Write-Host

  $expression = Get-RegularExpression

  while ($expression -ine "EXIT")
  {
    $lines | Select-String $expression -AllMatches
    Write-Host

    $expression = Get-RegularExpression
    Write-Host
  }

  Write-Host
  return Exit-Script
}