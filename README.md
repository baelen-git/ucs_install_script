# UCS_Install_script

This script can provision a new UCS enviornment for you. <br>
The script has been developed by Boris Aelen. <br>
Mail: borisaelen@gmail.com <br>
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
Make a copy of the sensitive_information-template.ps1 and name it: sensitive_information.ps1.<br>
Then configure all the settings in the file.<br>
If you want you can also edit the other variables in the main script file to create the UCS environment you want.<br>
