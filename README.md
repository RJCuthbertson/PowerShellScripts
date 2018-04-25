# **PowerShell Scripts**

Just a place for me to throw some of my PowerShell scripts.

All scripts contained in this repository are released copyleft under the GNU General Public License V3.0.

## **File Breakdown**

A short explanation of the files in this repository follows:

### **Scripts (`\.ps1$`)**

* **Common.ps1:**
  This file contains general purpose, utility functions for working with the file system, programs, registry, and scripts.

* **CommonUX.ps1:**
  This file is for general purpose, utility functions intended to be used throughout the other scripts in this repository. Functions in this file handle display formatting and / or presentation, and are placed here to allow for a consistent UX across the other scripts in this repository.

* **Install.ps1:**
  An installer script to :sparkles: auto-magically :sparkles: copy the scripts and requisite files in this repository to the user profile folder. Just call `.\Install.ps1` and the rest just takes care of itself, as it should.

* **profile.ps1:**
  A PowerShell profile initialization script (`$PROFILE.CurrentUserAllHosts`) that configures the shell on load. Mostly setting up aliases and ensuring helpful modules are loaded.

* **Regex.ps1:**
  This file houses a single cmdlet, `Run-RegexMatchLoop`, a user input loop that prompts for a Regular Expression and matches lines of a given text document (or the default wordlist).

* **SelfElevatingScriptTemplate.ps1**
  This is a script template that shows how to auto-elevate a script to be run as an administrator if it was not run with administrator privileges from the start.

* **Win10Customization.ps1:**
  This script automates some of the tasks related to customization of Windows 10 that I've found myself performing multiple times.

### **Not Scripts (`.(?<!\.ps1)$`)**

* **DefaultWordlist.txt:**
  A wordlist document with 354,985 words / lines, providing a decent range of input words for testing simple Regular Expressions. Used as the default source document for the `Run-RegexMatchLoop` cmdlet in `Regex.ps1` if one is not provided by the user.

* **LICENSE:**
  The GNU General Public License Version 3. Because in America, legal stuff like this helps prevent you from being frivolously sued and / or helps you stop people from plagiarizing your work (though I honestly couldn&rsquo;t care less with this repository).

* **README.md:**
  This GMF Markdown document.