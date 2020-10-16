[![published](https://static.production.devnetcloud.com/codeexchange/assets/images/devnet-published.svg)](https://developer.cisco.com/codeexchange/github/repo/baelen-git/ucs_install_script)


# UCS_Install_script

This script can provision a new UCS enviornment for you. <br>
The script has been developed by Boris Aelen. <br>

Mail: boris@borisaelen.nl <br>
Twitter: https://twitter.com/borisaelen <br>

## DESCRIPTION
This script will provision the following UCS components for you:
-	DNS & NTP servers
-	Callhome profiles  (e-mail alerts)
-	AD Authentication
-	Config backups to an FTP server
-	MTU size 
-	Fabric Interconnect server porten
-	Fabric Interconnect Portchannel Uplinks
-	Tentant 
-	Serveral policies (BIOS/boot/firmware/maintenance/scrub/global/localdisk/diskgroup)
-	Several pools (server/uuid/mac/cimc)
-	VLANS
-	vNIC Templates
-	Service Profile Templates

NOTE: The script will update any already existing configuration in UCS.<br>
NOTE: The script assumes an UCS environment with default settings. <br>
      It won't remove any additional configuration that might be in the UCS environment and could mess up your config.<br>

## USAGE

Enable PowerShell to run scripts by bypassing the default execution policy for the current user:
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force. 

Make a copy of the sensitive_information-template.ps1 and name it: sensitive_information.ps1.<br>
Then configure all the settings in the file.<br>

Powershell knowledge is required to use this script, it is not very user friendly.
If you want you can also edit the other variables in the main script file to create the UCS environment you want.<br>

## Configuration

The script is very static and provisions the UCS environment following the best practises that I use personally.
If you don't want to use some parts of the script, please comment them out inside the script.

## DevNet Sandbox

There is no Sandbox at the moment that has Powershell version 5 or higher.

## Getting help

Feel free to send me an e-mail with questions.


