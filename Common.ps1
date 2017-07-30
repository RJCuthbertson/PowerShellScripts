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

Function Pause-Script()
{
  # The PowerShell ISE detection was pulled from:
  # https://adamstech.wordpress.com/2011/05/12/how-to-properly-pause-a-powershell-script/
  if (!$psISE)
  {
    try
    {
      Write-Host
      Write-Host -NoNewline 'Press any key to continue...'
      $x = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    catch [System.NotImplementedException]
    {
    }
  }

  Write-Host
  Clear-Workspace
}