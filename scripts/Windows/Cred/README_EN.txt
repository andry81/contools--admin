* README_EN.txt
* 2025.04.12
* contools--admin/wincred

1. DESCRIPTION
2. INSTRUCTIONS
2.1. Installation of PowerShell 5.1 for Windows 7/8.x/Server2012
2.2. Installation of PowerShell CredentialManager module
2.3. Add credentials
3. KNOWN ISSUES
3.1. Error message: `remote: Invalid username or password.`
     `fatal: Authentication failed for 'https://github.com/USER/REPO/'`
3.2. Warning and error message:
     `WARNING: Unable to resolve package source 'https://www.powershellgallery.com/api/v2'.`
     `PackageManagement\Save-Package : No match was found for the specified search criteria and module name 'CredentialManager'. ...`

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
Windows credentials maintain scripts.

-------------------------------------------------------------------------------
2. INSTRUCTIONS
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
2.1. Installation of PowerShell 5.1 for Windows 7/8.x/Server2012
-------------------------------------------------------------------------------
https://www.microsoft.com/en-us/download/details.aspx?id=54616

Files:

* W2K12-KB3191565-x64.msu
* Win8.1AndW2K12R2-KB3191564-x64.msu
* Win8.1-KB3191564-x86.msu
* Win7AndW2K8R2-KB3191566-x64.zip
* Win7-KB3191566-x86.zip

-------------------------------------------------------------------------------
2.2. Installation of PowerShell CredentialManager module
-------------------------------------------------------------------------------

1. >
   deploy/install-credential-manager.bat -elevate

-------------------------------------------------------------------------------
2.3. Add credentials
-------------------------------------------------------------------------------

1. >
   newcred.bat -elevate -- git:https://github.com USER PASS Enterprise
   newcred.bat -elevate -- git:https://USER@github.com USER PASS LocalMachine

-------------------------------------------------------------------------------
3. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
3.1. Error message: `remote: Invalid username or password.`
     `fatal: Authentication failed for 'https://github.com/USER/REPO/'`
-------------------------------------------------------------------------------
Details:
  * https://gist.github.com/andry81/4dc954fc98a84807195080c6d2c5bc72 :
    `GitHub credentials notable details and changes`
  * https://github.com/orgs/community/discussions/133133#discussioncomment-10443908 :
    `Whenever I want to push any change from my local to my github via
     terminal, showing "Remote: Invalid username or password." I deleted my
     personal token from the github and reinstalled the git in my system. But
     not working.`

The GitHub now requires 2 credentials instead of one as was before for
`https://github.com/USER/REPO` remotes:

1. Address: `git:https://github.com`
  User: `USER`
  Pass: `PASS`
  Persistence: `Enterprise`

*AND*

2. Address: `git:https://USER@github.com`
  User: `USER`
  Pass: `PASS`
  Persistence: `Local computer`

CAUTION:
  This must be with persistence `Local computer`, otherwise won't work!

CAUTION:
  This can not be added through the `Windows Credential Manager` nor
  `cmdkey.exe` utility.

NOTE:
  The details how to add through the PowerShell:
  https://serverfault.com/questions/920048/change-persistence-type-of-windows-credentials-from-enterprise-to-local-compu


The `Git Credential Manager`:
https://github.com/git-ecosystem/git-credential-manager

CAUTION:
  The variable `credential.helper=manager` is required to update the
  `Windows Credential Manager` records on each Git command call within the Git
  authentication attempt.

NOTE:
  The `Git Credential Manager` adds and updates the second record automatically
  in the installation and after.

NOTE:
  If the GitHub PAT is expired, then `Git Credential Manager` automatically
  removes it from the `Windows Credential Manager` records list.

-------------------------------------------------------------------------------
3.2. Warning and error message:
     `WARNING: Unable to resolve package source 'https://www.powershellgallery.com/api/v2'.`
     `PackageManagement\Save-Package : No match was found for the specified search criteria and module name 'CredentialManager'. ...`
-------------------------------------------------------------------------------
Details:
  https://github.com/PowerShell/PowerShellGallery/issues/153 :
  `Unable to resolve package source 'https://www.powershellgallery.com/api/v2'`

Reason:
  You've tried to save a module using deprecated TLS protocol version.

Solution:
  Use `deploy/save-*-module.*` scripts to workaround it.
