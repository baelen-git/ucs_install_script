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
If you want you can also edit the other variables in the main script file to create the UCS environment you want.<br>

Detailed instructions on how to install, configure, and get the project running. Call out any dependencies. This should be frequently tested and updated to make sure it works reliably, accounts for updated versions of dependencies, etc.

Configuration

If the code is configurable, describe it in detail, either here or in other documentation that you reference.
Usage

Show users how to use the code. Be specific. Use appropriate formatting when showing code snippets or command line output.
DevNet Sandbox

A great way to make your repo easy for others to use is to provide a link to a DevNet Sandbox that provides a network or other resources required to use this code. In addition to identifying an appropriate sandbox, be sure to provide instructions and any configuration necessary to run your code with the sandbox.
How to test the software

Provide details on steps to test, versions of components/dependencies against which code was tested, date the code was last tested, etc. If the repo includes automated tests, detail how to run those tests. If the repo is instrumented with a continuous testing framework, that is even better.
Known issues

Document any significant shortcomings with the code. If using GitHub Issues to track issues, make that known and provide any templates or conventions to be followed when opening a new issue.
Getting help

Instruct users how to get help with this code; this might include links to an issues list, wiki, mailing list, etc.

Example

If you have questions, concerns, bug reports, etc., please create an issue against this repository.
Getting involved

This section should detail why people should get involved and describe key areas you are currently focusing on; e.g., trying to get feedback on features, fixing certain bugs, building important pieces, etc. Include information on how to setup a development environment if different from general installation instructions.

General instructions on how to contribute should be stated with a link to CONTRIBUTING file.
Credits and references

    Projects that inspired you
    Related projects
    Books, papers, talks, or other sources that have meaningful impact or influence on this code







