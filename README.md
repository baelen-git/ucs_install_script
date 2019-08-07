# UCS_Install_script

This script can provision a new UCS enviornment for you. 
The script has been developed by Boris Aelen.
Mail: borisaelen@gmail.com
Twitter: https://twitter.com/borisaelen

.DESCRIPTION
This script will provision the following UCS components for you:
o	DNS & NTP servers
o	Callhome profiles  (e-mail alerts)
o	AD Authentication
o	Config backups to an FTP server
o	MTU size 
o	Fabric Interconnect server porten
o	Fabric Interconnect Portchannel Uplinks
o	Tentant 
o	Serveral policies (BIOS/boot/firmware/maintenance/scrub/global/localdisk/diskgroup)
o	Several pools (server/uuid/mac/cimc)
o	VLANS
o	vNIC Templates
o	Service Profile Templates

NOTE: The script will update any already existing configuration in UCS.
NOTE: The script assumes an UCS environment with default settings. 
      It won't remove any additional configuration that might be in the UCS environment and could mess up your config.

.USAGE
Make a copy of the sensitive_information-template.ps1 and name it: sensitive_information.ps1.
Then configure all the settings in the file.

If you want you can also edit the other variables in the main script file to create the UCS environment you want.
