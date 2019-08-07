#requires -version 4
<#
.NOTES
Information on running PowerShell scripts can be found here:
    -http://ss64.com/ps/syntax-run.html
    -https://technet.microsoft.com/en-us/library/bb613481.aspx

File Name: ucs_install_script.ps1
Author: Boris Aelen 
Version: 1.0 
Date: 07 Aug 2019
Location: Amsterdam, The Netherlands

.COMPONENT  
    -PowerShell version 4.0 or greater required (which requires .NET Framework 4.5 or greater be installed first)
    -Cisco UCS PowerTool version 2.5.1 or higher: https://software.cisco.com/download/home/286305108/type/284574017//

.SYNOPSIS
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

.EXAMPLE
.\ucs_install_script.ps1
Running without any parameters use all the defaults you have configured in the script itself.
First edit this script file and the sensitive_information.ps1 file before you kick off the script. 

.LINK
www.borisaelen.nl
#>

############ DON'T forget the manual steps #################

#You can comment out the lines below after you've done them.
log "Please first make sure all the variables have been configured in the sensitive_information.ps1 and the ucs_install_script.ps1." -ForegroundColor RED -BackgroundColor Black
exit 

#Licenties via de Web GUI toevoegen
#Comment these 2 lines out if you've done them 
log "Please don't forget to install licences and firmware manualy (for now, later version of the script might install firmware for you)" -ForegroundColor RED -BackgroundColor Black
exit 

#firmware Upgrade
#Send-UcsFirmware -Path H:\ucs-6300-k9-bundle-infra.4.0.4b.A.bin
#Send-UcsFirmware -Path H:\ucs-k9-bundle-c-series.4.0.4b.C.bin
#via de gui de installatie starten van INFRA en daarna van Servers

#>

#region default variables

############ Below all settings which are generic for this customer ##########
#I've installed the UCS Powertool module in my homedrive so adding that path.
$env:PSModulePath = "$env:PSModulePath;H:\Documents\WindowsPowerShell\Modules"

#Source the file with the Sensitive information 
. ./sensitive_information.ps1

#$PSScriptRoot = "H:\Documents"
$Logfile   = "$PSScriptRoot\UCS_Installation_$($UCS)_"  + (Get-Date).ToString("yyyyMMdd_HHmm") + ".log"

$user = "admin"
$password = $UCS_pwd | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $password) 

$UCS_FIports = 1..32
$UCS_UplinkPorts = 29..32
$UCS_Tenant_Name = "T01"
$UCS_Mtu = "9216"
$UCS_Power_policy = "grid"
$UCS_Discovery_policy = "2-link"
$UCS_Discovery_policy_aggr = "port-channel"
$UCS_BIOS_Pol_1 = "$UCS_Tenant_Name-ESX"
$UCS_BIOS_Pol_1_Cstate = "disabled"
$UCS_BIOS_Pol_1_powertech = "custom"
$UCS_BIOS_Pol_1_quietboot = "disabled"

$UCS_BIOS_Pol_2 = "$UCS_Tenant_Name-WINDOWS"
$UCS_BIOS_Pol_2_Cstate = "disabled"
$UCS_BIOS_Pol_2_powertech = "custom"
$UCS_BIOS_Pol_2_quietboot = "disabled"

$UCS_Boot_pol_1 = "$UCS_Tenant_Name-SDBoot"
$UCS_Boot_pol_2 = "$UCS_Tenant_Name-SSDBoot"
$UCS_Boot_pol_rebootonupdate = "yes"
$UCS_Boot_pol_enforce_vnic_name = "yes"
$UCS_Boot_pol_bootmode = "legacy"

$UCS_Firmware_Pol = "$UCS_Tenant_Name-M5"
$UCS_C_Firmware_version = "4.0(4b)C"

$UCS_Localdisk_pol_1 = "$UCS_Tenant_Name-SD-R1"
$UCS_Localdisk_pol1_flexflash = "enable"
$UCS_Localdisk_pol1_mode = "any-configuration"

$UCS_Localdisk_pol_2 = "$UCS_Tenant_Name-SSD-R1"
$UCS_Localdisk_pol2_flexflash = "disable"
$UCS_Localdisk_pol2_mode = "raid-mirrored"

$UCS_Main_pol = "$UCS_Tenant_Name-UserAck"
$UCS_Main_pol_action = "user-ack"
$UCS_Main_pol_trigger =  "on-next-boot"

$UCS_Timezone = @{Timezone="Europe/Amsterdam"; }

$UCS_Backup_Fullstate = @{  
    AdminState="enable"; 
    Pwd=$UCS_backup_pwd; 
    Schedule="1day"; 
    RemoteFile="/$UCS/full_state_backup"; 
    Descr="Database Backup Policy"; 
    User="UCS"; 
    Host=$UCS_ftp_server; 
    Proto="ftp"; 
    Name="default"; 
}

$UCS_Backup_config = @{
    AdminState="enable"; 
    Pwd=$UCS_backup_pwd; 
    RemoteFile="/$UCS/all_config_backup"; 
    Descr="Configuration Export Policy"; 
    User="UCS"; 
    Host=$UCS_ftp_server;
    Proto="ftp"; 
    Name="default"; 
}

#Configure The Callhome Profile
$UCS_callhome_profile = @{
    AlertGroups = "all","ciscoTac","diagnostic","environmental" 
    Level = "notification" 
    Name ="Send_mail" 
}

$UCS_LdapGroupRule = @{
    Authorization = "enable"
    TargetAttr = "memberOf"    
    Traversal = "recursive" 
    UsePrimaryGroup = "no"
}

$UCS_Scrub_pol_scrubsd = @{
    Org = $UCS_Tenant_Name
    Name =  "$UCS_Tenant_Name-ScrubSDCard"
    FlexFlashScrub = "yes"
    DiskScrub = "no"
    BiosSettingsScrub = "no"
}

$UCS_Scrub_pol_noscrub = @{
    Org = $UCS_Tenant_Name
    Name =  "$UCS_Tenant_Name-NoScrub"
    FlexFlashScrub = "no"
    DiskScrub = "no"
    BiosSettingsScrub = "no"
}

$UCS_Server_pool_qual_1 = "$UCS_Tenant_Name-All_C240-M5S"
$UCS_Server_pool_qual_1_id = "UCSC-C240-M5S"
$UCS_Server_pool_1 = "$UCS_Tenant_Name-VDI"

$UCS_Server_pool_qual_2 = "$UCS_Tenant_Name-All_MGMT"
$UCS_Server_pool_qual_2_id = "UCSC-C220-M5SX"
$UCS_Server_pool_qual_2_cores = "16"
$UCS_Server_pool_2 = "$UCS_Tenant_Name-MGMT"

$UCS_Server_pool_qual_3 = "$UCS_Tenant_Name-All_CV"
$UCS_Server_pool_qual_3_id = "UCSC-C220-M5SX"
$UCS_Server_pool_qual_3_cores = "32"
$UCS_Server_pool_3 = "$UCS_Tenant_Name-CV"

$UCS_uuid_pool = "$UCS_Tenant_Name-$Site-UUID01"
$UCS_uuid_order = "sequential"
$UCS_uuid_from = "$($UCS_domain)01-000000000001"
$UCS_uuid_to = "$($UCS_domain)01-000000000100"

$UCS_Vlan_range = 3200..3966
$UCS_Vlan_sharing = "none"


$UCS_Network_control_pol = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-CDP"
    Cdp = "enabled"
    LldpReceive = "enabled"
    LldpTransmit = "enabled"
    MacRegisterMode = "only-native-vlan"
    UplinkFailAction = "link-down"
}

$UCS_Mac_order = "sequential"
$UCS_Mac_pool_1 = "$UCS_Tenant_Name-MAC-A"
$UCS_Mac_pool_1_from = "00:25:B5:$($UCS_domain):0A:00"
$UCS_Mac_pool_1_to = "00:25:B5:$($UCS_domain):0A:FF"

$UCS_Mac_pool_2 = "$UCS_Tenant_Name-MAC-B"
$UCS_Mac_pool_2_from = "00:25:B5:$($UCS_domain):0B:00"
$UCS_Mac_pool_2_to = "00:25:B5:$($UCS_domain):0B:FF"

$UCS_Mac_pool_3 = "$UCS_Tenant_Name-MAC-C"
$UCS_Mac_pool_3_from = "00:25:B5:$($UCS_domain):0C:00"
$UCS_Mac_pool_3_to = "00:25:B5:$($UCS_domain):0C:FF"

$UCS_vNIC_tmpl_1 = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-ESX-MGMT"
    Mtu = 1500
    Descr = "vNIC ESX MGMT"
    Target = "adaptor"
    SwitchID = "A-B"
    RedundancyPairType = "none"
    TemplType = "updating-template"
    CdnSource = "vnic-name"
    NwCtrlPolicyName= $UCS_Network_control_pol.Name
    IdentPoolName = $UCS_Mac_pool_3
}

$UCS_vNIC_tmpl_2 = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-ESX-A"
    Mtu = 9000
    Descr = "vNIC ESX Data Fabric A"
    Target = "adaptor"
    SwitchID = "A"
    RedundancyPairType = "none"
    TemplType = "updating-template"
    CdnSource = "vnic-name"
    NwCtrlPolicyName= $UCS_Network_control_pol.Name
    IdentPoolName = $UCS_Mac_pool_1
}

$UCS_vNIC_tmpl_3 = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-ESX-B"
    Mtu = 9000
    Descr = "vNIC ESX Data Fabric B"
    Target = "adaptor"
    SwitchID = "B"
    RedundancyPairType = "none"
    TemplType = "updating-template"
    CdnSource = "vnic-name"
    NwCtrlPolicyName= $UCS_Network_control_pol.Name
    IdentPoolName = $UCS_Mac_pool_2
}

$UCS_vNIC_tmpl_4 = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-CV-PRD"
    Mtu = 1500
    Descr = "vNIC Commvault Productie"
    Target = "adaptor"
    SwitchID = "A-B"
    RedundancyPairType = "none"
    TemplType = "updating-template"
    CdnSource = "vnic-name"
    NwCtrlPolicyName= $UCS_Network_control_pol.Name
    IdentPoolName = $UCS_Mac_pool_1
}

$UCS_vNIC_tmpl_5 = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-CV-DDB"
    Mtu = 9000
    Descr = "vNIC Commvault DDB"
    Target = "adaptor"
    SwitchID = "B-A"
    RedundancyPairType = "none"
    TemplType = "updating-template"
    CdnSource = "vnic-name"
    NwCtrlPolicyName= $UCS_Network_control_pol.Name
    IdentPoolName = $UCS_Mac_pool_2
}

$UCS_vNIC_tmpl_6 = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-CV-BCK"
    Mtu = 9000
    Descr = "vNIC Commvault Backup"
    Target = "adaptor"
    SwitchID = "A-B"
    RedundancyPairType = "none"
    TemplType = "updating-template"
    CdnSource = "vnic-name"
    NwCtrlPolicyName= $UCS_Network_control_pol.Name
    IdentPoolName = $UCS_Mac_pool_1
}

$UCS_vNIC_tmpl_7 = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-CV-iSCSi"
    Mtu = 9000
    Descr = "vNIC Commvault iSCSi"
    Target = "adaptor"
    SwitchID = "B-A"
    RedundancyPairType = "none"
    TemplType = "updating-template"
    CdnSource = "vnic-name"
    NwCtrlPolicyName= $UCS_Network_control_pol.Name
    IdentPoolName = $UCS_Mac_pool_2
}

$UCS_vNIC_tmpl_1_defaultvlan = 3951
$UCS_vNIC_tmpl_1_vlanrange = 3953,3951
$UCS_vNIC_tmpl_2_defaultvlan = 3951
$UCS_vNIC_tmpl_2_vlanrange = 3200..3966
$UCS_vNIC_tmpl_3_defaultvlan = 3951
$UCS_vNIC_tmpl_3_vlanrange = 3200..3966

$UCS_vNIC_tmpl_4_defaultvlan = 3959
$UCS_vNIC_tmpl_4_vlanrange = $UCS_vNIC_tmpl_4_defaultvlan
$UCS_vNIC_tmpl_5_defaultvlan = 3963
$UCS_vNIC_tmpl_5_vlanrange = $UCS_vNIC_tmpl_5_defaultvlan
$UCS_vNIC_tmpl_6_defaultvlan = 3960
$UCS_vNIC_tmpl_6_vlanrange = $UCS_vNIC_tmpl_6_defaultvlan
$UCS_vNIC_tmpl_7_defaultvlan = 3962
$UCS_vNIC_tmpl_7_vlanrange = $UCS_vNIC_tmpl_7_defaultvlan

#Create Disk Group Policies
$UCS_Diskgroup_pol_1 = @{
    Org =$UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-R1-CV-OS"
    Descr = "De raidconfig voor de OS disks van Commvault"
    Raidlevel = "mirror"
}
$UCS_Diskgroup_pol_1_qual = @{
    DriveType = "SSD"
    MinDriveSize = "450"
    NumDrives  = "2"
}

$UCS_Diskgroup_pol_2 = @{
    Org =$UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-R1-CV-INDX"
    Descr = "De raidconfig voor de Index disks van Commvault"
    Raidlevel = "mirror"
}
$UCS_Diskgroup_pol_2_qual = @{
    DriveType = "SSD"
    MinDriveSize = "1800"
    NumDrives  = "2"
}

$UCS_Diskgroup_pol_3 = @{
    Org =$UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-R1-CV-Dedup"
    Descr = "De raidconfig voor de Dedup  disks van Commvault"
    Raidlevel = "mirror"
}
$UCS_Diskgroup_pol_3_qual = @{
    DriveType = "SSD"
    MinDriveSize = "3600"
    NumDrives  = "2"
}

$UCS_ExMgmt_pool = @{
    Org = "root"
    Name = "$UCS_Tenant_Name-ext-mgmt"
    AssignmentOrder = "sequential"
}

$UCS_vlangroup = "CiMC_VLAN_Group"
$UCS_CIMC_vlan = "3964"

$UCS_SPT_1 = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-SPT_VDI"
    BiosProfileName = $UCS_BIOS_Pol_1
    Descr = "Service Profile Template voor alle VDI Servers"
    ExtIPPoolName = $UCS_ExMgmt_pool.Name
    HostFwPolicyName = $UCS_Firmware_Pol 
    LocalDiskPolicyName = $UCS_Localdisk_pol_1
    MaintPolicyName = $UCS_Main_pol
    ScrubPolicyName = $UCS_Scrub_pol_noscrub.Name
    Type = "updating-template"
    BootPolicyName = $UCS_Boot_pol_1
    IdentPoolName = $UCS_uuid_pool
}

$UCS_SPT_1_vNIC_mgmt = @{
    AdaptorProfileName = "VMWare" 
    Name = "vNIC-MGMT"
    NwTemplName = $UCS_vNIC_tmpl_1.Name
    Order = "1" 
}
$UCS_SPT_1_vNIC_A = @{
    AdaptorProfileName = "VMWare" 
    Name = "vNIC-A" 
    NwTemplName = $UCS_vNIC_tmpl_2.Name
    Order = "2" 
}
$UCS_SPT_1_vNIC_B = @{
    AdaptorProfileName = "VMWare" 
    Name = "vNIC-B" 
    NwTemplName = $UCS_vNIC_tmpl_3.Name
    Order = "3" 
}

$UCS_SPT_2 = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-SPT_MGMT"
    BiosProfileName = $UCS_BIOS_Pol_1
    Descr = "Service Profile Template voor alle MGMT Servers"
    ExtIPPoolName = $UCS_ExMgmt_pool.Name
    HostFwPolicyName = $UCS_Firmware_Pol 
    LocalDiskPolicyName = $UCS_Localdisk_pol_1
    MaintPolicyName = $UCS_Main_pol
    ScrubPolicyName = $UCS_Scrub_pol_noscrub.Name
    Type = "updating-template"
    BootPolicyName = $UCS_Boot_pol_1
    IdentPoolName = $UCS_uuid_pool
}

$UCS_SPT_3 = @{
    Org = $UCS_Tenant_Name
    Name = "$UCS_Tenant_Name-SPT_CV"
    BiosProfileName = $UCS_BIOS_Pol_2
    Descr = "Service Profile Template voor alle Commvault Servers"
    ExtIPPoolName = $UCS_ExMgmt_pool.Name
    HostFwPolicyName = $UCS_Firmware_Pol 
    LocalDiskPolicyName = $UCS_Localdisk_pol_2
    MaintPolicyName = $UCS_Main_pol
    ScrubPolicyName = $UCS_Scrub_pol_noscrub.Name
    Type = "updating-template"
    BootPolicyName = $UCS_Boot_pol_2
    IdentPoolName = $UCS_uuid_pool
}
$UCS_SPT_3_PRD = @{
    AdaptorProfileName = "Windows" 
    Name = "vNIC-PRD"
    NwTemplName = $UCS_vNIC_tmpl_4.Name
    Order = "1" 
}
$UCS_SPT_3_DDB = @{
    AdaptorProfileName = "Windows" 
    Name = "vNIC-DDB"
    NwTemplName = $UCS_vNIC_tmpl_5.Name
    Order = "2" 
}
$UCS_SPT_3_BCK = @{
    AdaptorProfileName = "Windows" 
    Name = "vNIC-BCK"
    NwTemplName = $UCS_vNIC_tmpl_6.Name
    Order = "3" 
}
$UCS_SPT_3_iSCSi = @{
    AdaptorProfileName = "Windows" 
    Name = "vNIC-iSCSi"
    NwTemplName = $UCS_vNIC_tmpl_7.Name
    Order = "4" 
}

#endregion default variables

#region Functions
Function New-vNic-tmpl () { 
    param($template,$vlanrange,$defaultvlan)
    log "Creating vNIC Template: $($template.Name)... " -NoNewLine
    $vnic = Add-UcsVnicTemplate @template -ModifyPresent
    log "DONE" -result -ForegroundColor GREEN
    log "`tAdding VLAN to vNIC Template with ID:" -NoNewLine

    foreach ($vlan in $vlanrange){
        $args = @{
            Name = $vlan
        }

        if ($vlan -eq $defaultvlan) { 
            $args.Add("DefaultNet","true")
        } else { 
            $args.Add("DefaultNet","false")
        }
        log " $vlan" -NoNewLine
        $vnic | Add-UcsVnicInterface @args -ModifyPresent | Out-Null
    }
    log "DONE" -result -ForegroundColor GREEN
}

Function Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$logstring
        ,
        [Parameter(Mandatory=$false)]
        [switch]$NoNewLine
        ,
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor
        ,
        [Parameter(Mandatory=$false)]
        [string]$BackgroundColor
        ,
        [Parameter(Mandatory=$false)]
        [switch]$result
    )

    $strDatum =  (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") + ":"

    $write_args = @{
        Object = $Logstring
        NoNewLine = $NoNewLine
    }

    $log_args = @{
        Path = $logfile 
        NoNewLine = $NoNewLine
    }
    
    if ($result) {
        $logstring = ("[" +  $($logstring) +"]").ToUpper()
        $log_args.Add("Value", "`t" + $logstring)
        $write_args.Object = $logstring
        $startposx = $Host.UI.RawUI.windowsize.width - 20
        $startposy = $Host.UI.RawUI.CursorPosition.Y
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $startposx,$startposy
    } else {
        if ($NoNewLine) {
            $log_args.Add("Value", "$($logstring)") 
        } else {
           $log_args.Add("Value", "$($strDatum) $($logstring)") 
        }
    }
    
    if ($Foregroundcolor) { $write_args.Add("ForegroundColor", $ForegroundColor)  } 
    if ($BackgroundColor) { $write_args.Add("BackgroundColor", $BackgroundColor)  } 
    if (!(test-path $PSScriptRoot)) {new-item -path (split-path $PSScriptRoot) -name (split-path $PSScriptRoot -leaf) -type directory -force}
    if (!$DryRun){  Add-content @log_args }
    write-host @write_args
}

#endregion Functions

#region Main
import-module Cisco.UCSManager

log "Disconnecting from all existing UCS environments..." -NoNewLine
Disconnect-Ucs | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "Going to connect to UCS $UCS..." -NoNewLine
    Connect-Ucs $UCS -Credential $cred | out-null
log "DONE" -result -ForegroundColor GREEN

#Algemene informatie 
log "Setting Owner: $UCS_Tenant_Desc Site: $Site ..." -NoNewLine
    Add-UcsManagedObject -ModifyPresent  -ClassId TopSystem -PropertyMap @{Descr=$UCS_Tenant_Desc; Site=$Site; Owner=$UCS_Tenant_Desc; Dn="sys"; }  | out-null
log "DONE" -result -ForegroundColor GREEN

#Configure the Fullstate and Config Backups
log "Configure the Fullstate and Config Backups..." -NoNewLine
Get-UcsOrg -Level root  | Add-UcsManagedObject -ModifyPresent  -ClassId MgmtBackupPolicy -PropertyMap $UCS_Backup_Fullstate | Out-Null
Get-UcsOrg -Level root  | Add-UcsManagedObject -ModifyPresent  -ClassId MgmtCfgExportPolicy -PropertyMap $UCS_Backup_config  | Out-Null
Get-UcsOrg -Level root  | Add-UcsManagedObject -ModifyPresent  -ClassId MgmtBackupExportExtPolicy -PropertyMap @{ AdminState="enable"; } | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Configure the MTU size 
log "Configured the Global MTU size to $UCS_Mtu in the BestEffort QOS Class..." -NoNewLine
    Add-UcsManagedObject -ModifyPresent  -ClassId QosclassEthBE -PropertyMap @{Dn="fabric/lan/classes/class-best-effort"; Mtu="$UCS_Mtu"; } | Out-Null
log "DONE" -result -ForegroundColor GREEN


#Cofiguring the NTP servers
log "Configure the timezone and NTP servers..." -NoNewLine
$timezone = Get-UcsSvcEp | Add-UcsManagedObject -ModifyPresent  -ClassId CommDateTime -PropertyMap $UCS_Timezone
add-UcsNtpServer -Name $UCS_NTP_server_1 -ModifyPresent  -Timezone $timezone | Out-Null
add-UcsNtpServer -Name $UCS_NTP_server_2 -ModifyPresent  -Timezone $timezone | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Cofiguring the DNS Servers
log "Configure the DNS servers..." -NoNewLine
Get-UcsDns | Add-UcsDnsServer -Name $UCS_ExMgmt_pool_block.PrimDns -ModifyPresent | Out-Null
Get-UcsDns | Add-UcsDnsServer -Name $UCS_ExMgmt_pool_block.SecDns -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Configure The Callhome Profile
log "Configure the CallHome Profiles..." -NoNewLine
Add-UcsManagedObject -ModifyPresent  -ClassId CallhomeSource -PropertyMap $UCS_Callhome | Out-Null
Add-UcsManagedObject -ModifyPresent  -ClassId CallhomeSmtp -PropertyMap @{Host="$UCS_SMTP_server"; Dn="call-home/smtp"; } | Out-Null
Add-UcsManagedObject -ModifyPresent  -ClassId CallhomeEp -PropertyMap @{AdminState="on"; Dn="call-home"; } | Out-Null
$mo = Add-UcsCallhomeProfile @UCS_callhome_profile -ModifyPresent
$mo | Add-UcsCallhomeRecipient $UCS_alert_mailadres -ModifyPresent  | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Configure LDAP authentication
log "Configure the AD Authentication..." -NoNewLine
$mo = Add-UcsAuthDomain -Name $UCS_Domainname -ModifyPresent 
$mo | Set-UcsAuthDomainDefaultAuth -Realm "ldap" -Use2Factor "no" -Force | Out-Null
$mo = Add-UcsLdapProvider @UCS_LdapProvider -ModifyPresent 
$mo | Add-UcsLdapGroupRule @UCS_LdapGroupRule -ModifyPresent | Out-Null
$mo = Add-UcsLdapGroupMap -Name $UCS_Ldap_Group_name -ModifyPresent
$mo | Add-UcsUserRole -Name "admin" -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Configure portchannel
log "Creating 2 Portchannels..." -NoNewLine
$portchannel_a = Add-UcsUplinkPortChannel -FiLanCloud A -PortId 101 -Name VPC101 -Descr $PO1_desc -ModifyPresent 
$portchannel_b = Add-UcsUplinkPortChannel -FiLanCloud B -PortId 102 -Name VPC102 -Descr $PO2_desc -ModifyPresent 
log "DONE" -result -ForegroundColor GREEN

log "Configuring all FI ports..." 
foreach ($port in $UCS_FIports) {
    if ($UCS_Serverports.Contains($port)) {
        log "`tPort $port : Server port..." -NoNewLine
        Get-UcsFabricServerCloud -id A |  Add-UcsServerPort -AdminState enabled -PortId $port -SlotId 1 -ModifyPresent | Out-Null 
        Get-UcsFabricServerCloud -id B |  Add-UcsServerPort -AdminState enabled -PortId $port -SlotId 1 -ModifyPresent | Out-Null
        log "DONE" -result -ForegroundColor GREen
    } else {
        if ($UCS_UplinkPorts.Contains($port)) {
            log "`tPort $port : Uplink port..." -NoNewLine
            Add-UcsUplinkPort -PortId $port -SlotId 1 -ModifyPresent -FiLanCloud A | Out-Null
            Add-UcsUplinkPort -PortId $port -SlotId 1 -ModifyPresent -FiLanCloud B | out-null
            Add-UcsUplinkPortChannelMember -UplinkPortChannel $portchannel_a -PortId $port -SlotId 1 -ModifyPresent | out-null
            Add-UcsUplinkPortChannelMember -UplinkPortChannel $portchannel_b -PortId $port -SlotId 1 -ModifyPresent | out-null
            log "DONE" -result -ForegroundColor GREen
        } else {
            log "`tPort $port : not used, unconfiguring..." -NoNewLine
                Get-UcsAppliancePort -PortId $port| Remove-UcsAppliancePort -Force| out-null
                Get-UcsServerPort -PortId $port | Remove-UcsServerPort -Force| out-null
                Get-UCSUplinkPort -PortId $port | Remove-UcsUplinkPort -Force| out-null
                Get-UcsFiSanCloud |  Get-UcsFabricFcoeSanEp -SlotId 1 -PortId $port | Remove-UcsFabricFcoeSanEp -Force| Out-Null
                Get-UcsFabricFcStorageCloud |  Get-UcsFcoeStoragePort -SlotId 1 -PortId $port | Remove-UcsFcoeStoragePort -Force| Out-Null
            log "DONE" -result -ForegroundColor GREEN
        }
    }
}


#create the first Tenant
log "Creating the Tenant: $UCS_Tenant_Name ..." -NoNewLine
Add-UcsOrg -Name $UCS_Tenant_Name -Descr $UCS_Tenant_Desc -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Configureer verschillende UCS Glogal Equipment policies
log "Settings different UCS Global Equiment Policies..." -NoNewLine
 Get-UcsChassisDiscoveryPolicy |  Set-UcsChassisDiscoveryPolicy -Action $UCS_Discovery_policy -LinkAggregationPref $UCS_Discovery_policy_aggr -Force | Out-Null
 Get-UcsPowerControlPolicy | Set-UcsPowerControlPolicy -Redundancy $UCS_Power_policy -Force | Out-Null
 Get-UcsTopInfoPolicy | Set-UcsTopInfoPolicy -State enabled -Force | Out-Null
 Get-UcsFirmwareAutoSyncPolicy | Set-UcsFirmwareAutoSyncPolicy -SyncState 'User Acknowledge' -Force | Out-Null
 Get-UcsPowerMgmtPolicy | Set-UcsPowerMgmtPolicy -Profiling yes -Force | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Configureer verschillende UCS Glogal Equipment policies
log "Creating the BIOS policies:" 
log "`t$UCS_BIOS_Pol_1 " -NoNewLine
$bios_pol_1 =  Add-UcsBiosPolicy -Org $UCS_Tenant_Name -Name $UCS_BIOS_Pol_1 -ModifyPresent 
Set-UcsBiosVfProcessorCState -BiosPolicy $bios_pol_1 -VpProcessorCState $UCS_BIOS_Pol_1_Cstate -Force | Out-Null
Set-UcsBiosVfProcessorC1E -BiosPolicy $bios_pol_1 -VpProcessorC1E $UCS_BIOS_Pol_1_Cstate -Force| Out-Null
Set-UcsBiosVfProcessorC3Report -BiosPolicy $bios_pol_1 -VpProcessorC3Report $UCS_BIOS_Pol_1_Cstate -Force | Out-Null
Set-UcsBiosVfProcessorC6Report -BiosPolicy $bios_pol_1 -VpProcessorC6Report $UCS_BIOS_Pol_1_Cstate -Force | Out-Null
Set-UcsBiosVfProcessorC7Report -BiosPolicy $bios_pol_1 -VpProcessorC7Report $UCS_BIOS_Pol_1_Cstate -Force | Out-Null
Set-UcsBiosVfProcessorEnergyConfiguration -BiosPolicy $bios_pol_1 -VpPowerTechnology $UCS_BIOS_Pol_1_powertech -Force | Out-Null
Set-UcsBiosVfQuietBoot -BiosPolicy $bios_pol_1 -VpQuietBoot $UCS_BIOS_Pol_1_quietboot -Force | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "`t$UCS_BIOS_Pol_2 " -NoNewLine
$bios_pol_2 =  Add-UcsBiosPolicy -Org $UCS_Tenant_Name -Name $UCS_BIOS_Pol_2 -ModifyPresent
Set-UcsBiosVfProcessorCState -BiosPolicy $bios_pol_2 -VpProcessorCState $UCS_BIOS_Pol_2_Cstate -Force | Out-Null
Set-UcsBiosVfProcessorC1E -BiosPolicy $bios_pol_2 -VpProcessorC1E $UCS_BIOS_Pol_2_Cstate -Force | Out-Null
Set-UcsBiosVfProcessorC3Report -BiosPolicy $bios_pol_2 -VpProcessorC3Report $UCS_BIOS_Pol_2_Cstate -Force | Out-Null
Set-UcsBiosVfProcessorC6Report -BiosPolicy $bios_pol_2 -VpProcessorC6Report $UCS_BIOS_Pol_2_Cstate -Force | Out-Null
Set-UcsBiosVfProcessorC7Report -BiosPolicy $bios_pol_2 -VpProcessorC7Report $UCS_BIOS_Pol_2_Cstate -Force| Out-Null
Set-UcsBiosVfProcessorEnergyConfiguration -BiosPolicy $bios_pol_2 -VpPowerTechnology $UCS_BIOS_Pol_2_powertech -Force| Out-Null
Set-UcsBiosVfQuietBoot -BiosPolicy $bios_pol_2 -VpQuietBoot $UCS_BIOS_Pol_2_quietboot -Force| Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create the Boot Policy
log "Creating the BOOT policies:" 
log "`t$UCS_Boot_pol_1 " -NoNewLine
$boot_pol_1 = Add-UcsBootPolicy -Org $UCS_Tenant_Name -Name $UCS_Boot_pol_1 -BootMode $UCS_Boot_pol_bootmode -EnforceVnicName $UCS_Boot_pol_enforce_vnic_name -RebootOnUpdate $UCS_Boot_pol_rebootonupdate -ModifyPresent 
Add-UcsLsbootVirtualMedia -BootPolicy $boot_pol_1 -Access read-only -Order 1 -ModifyPresent | Out-Null
$boot_pol_1 | Add-UcsLsbootStorage -ModifyPresent  |  Add-UcsLsbootLocalStorage -ModifyPresent | Add-UcsLsbootUsbFlashStorageImage -Order 2 -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "`t$UCS_Boot_pol_2 " -NoNewLine
$boot_pol_2 = Add-UcsBootPolicy -Org $UCS_Tenant_Name -Name $UCS_Boot_pol_2 -BootMode $UCS_Boot_pol_bootmode -EnforceVnicName $UCS_Boot_pol_enforce_vnic_name -RebootOnUpdate $UCS_Boot_pol_rebootonupdate -ModifyPresent
Add-UcsLsbootVirtualMedia -BootPolicy $boot_pol_2 -Access read-only -ModifyPresent | Out-Null
$boot_pol_2 | Add-UcsLsbootStorage -ModifyPresent  |  Add-UcsLsbootLocalStorage -ModifyPresent | Add-UcsLsbootDefaultLocalImage -Order 2 -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create the Firmware Policy
log "Creating the Firmware Policy: $UCS_Firmware_Pol..." -NoNewLine
Add-UcsFirmwareComputeHostPack -Name $UCS_Firmware_Pol -Org $UCS_Tenant_Name -RackBundleVersion $UCS_C_Firmware_version -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create the Local Disk Policies
log "Creating the Local Disk Policies:"
log "`t$UCS_Localdisk_pol_1..." -NoNewLine
Add-UcsLocalDiskConfigPolicy -FlexFlashRAIDReportingState $UCS_Localdisk_pol1_flexflash -FlexFlashState $UCS_Localdisk_pol1_flexflash -Name $UCS_Localdisk_pol_1 -Org $UCS_Tenant_Name -ModifyPresent -Mode  $UCS_Localdisk_pol1_mode | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "`t$UCS_Localdisk_pol_2..." -NoNewLine
Add-UcsLocalDiskConfigPolicy -FlexFlashRAIDReportingState $UCS_Localdisk_pol2_flexflash -FlexFlashState $UCS_Localdisk_pol2_flexflash -Name $UCS_Localdisk_pol_2 -Org $UCS_Tenant_Name -ModifyPresent -Mode  $UCS_Localdisk_pol2_mode| Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create the Maintance Policy
log "Creating the Maintenance $UCS_Main_pol..." -NoNewLine
Add-UcsMaintenancePolicy -Org $UCS_Tenant_Name -Name $UCS_Main_pol -DataDisr $UCS_Main_pol_action -UptimeDisr $UCS_Main_pol_action -ModifyPresent -TriggerConfig $UCS_Main_pol_trigger | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create the Scrub Policy
log "Creating the Scrub Policy $($UCS_Scrub_pol_scrubsd.Name) ..." -NoNewLine
Add-UcsScrubPolicy @UCS_Scrub_pol_scrubsd -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "Creating the Scrub Policy $($UCS_Scrub_pol_noscrub.Name) ..." -NoNewLine
Add-UcsScrubPolicy @UCS_Scrub_pol_noscrub -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create the Server Pools
log "Creating the Server Pools:" 
log "`t$UCS_Server_pool_1..." -NoNewLine
$serverpool = Add-UcsServerPool -Org $UCS_Tenant_Name -Name $UCS_Server_pool_1 -ModifyPresent
$serverpool_qual = Add-UcsServerPoolQualification -Org $UCS_Tenant_Name -Name $UCS_Server_pool_qual_1 -ModifyPresent  
$serverpool_qual | Add-UcsServerModelQualification -Model $UCS_Server_pool_qual_1_id -ModifyPresent | Out-Null
Add-UcsServerPoolPolicy -Org $UCS_Tenant_Name -Name $UCS_Server_pool_1 -PoolDn $serverpool.Dn -Qualifier $UCS_Server_pool_qual_1 -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "`t$UCS_Server_pool_2..." -NoNewLine
$serverpool = Add-UcsServerPool -Org $UCS_Tenant_Name -Name $UCS_Server_pool_2 -ModifyPresent
$serverpool_qual = Add-UcsServerPoolQualification -Org $UCS_Tenant_Name -Name $UCS_Server_pool_qual_2 -ModifyPresent  
$serverpool_qual | Add-UcsServerModelQualification -Model $UCS_Server_pool_qual_2_id -ModifyPresent | Out-Null
$serverpool_qual | Add-UcsCpuQualification -MinCores $UCS_Server_pool_qual_2_cores -MaxCores $UCS_Server_pool_qual_2_cores -ModifyPresent  | Out-Null
Add-UcsServerPoolPolicy -Org $UCS_Tenant_Name -Name $UCS_Server_pool_2 -PoolDn $serverpool.Dn -Qualifier $UCS_Server_pool_qual_2 -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "`t$UCS_Server_pool_3..." -NoNewLine
$serverpool = Add-UcsServerPool -Org $UCS_Tenant_Name -Name $UCS_Server_pool_3 -ModifyPresent
$serverpool_qual = Add-UcsServerPoolQualification -Org $UCS_Tenant_Name -Name $UCS_Server_pool_qual_3 -ModifyPresent  
$serverpool_qual | Add-UcsServerModelQualification -Model $UCS_Server_pool_qual_3_id -ModifyPresent  | Out-Null
$serverpool_qual | Add-UcsCpuQualification -MinCores $UCS_Server_pool_qual_3_cores -MaxCores $UCS_Server_pool_qual_3_cores -ModifyPresent  | Out-Null
Add-UcsServerPoolPolicy -Org $UCS_Tenant_Name -Name $UCS_Server_pool_3 -PoolDn $serverpool.Dn -Qualifier $UCS_Server_pool_qual_3 -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create UUID Pool
log "Creating the UUID Pool $($UCS_uuid_pool)..." -NoNewLine
$uuid = Add-UcsUuidSuffixPool -Org $UCS_Tenant_Name -Name $UCS_uuid_pool -AssignmentOrder $UCS_uuid_order -ModifyPresent
$uuid | Add-UcsUuidSuffixBlock -From $UCS_uuid_from  -To $UCS_uuid_to -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create VLAN Pools
$lancloud = Get-UcsLanCloud
log "Creating the VLAN with id: " -NoNewLine
foreach ($vlanid in $UCS_Vlan_range){
    log "$vlanid " -NoNewLine
    Add-UcsVlan -LanCloud $lancloud -Name $vlanid -Id $vlanid -Sharing $UCS_Vlan_sharing -ModifyPresent | Out-Null
}
log "DONE" -result -ForegroundColor GREEN

#create Network Control Policy
log "Creating the Network Control Policy: $($UCS_Network_control_pol.Name)... " -NoNewLine
Add-UcsNetworkControlPolicy @UCS_Network_control_pol -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#create the MAC Pools
log "Creating the MAC Pool: $($UCS_Mac_pool_1)... " -NoNewLine
$mac_pool = Add-UcsMacPool -Org $UCS_Tenant_Name -Name $UCS_Mac_pool_1 -AssignmentOrder $UCS_Mac_order -ModifyPresent
$mac_pool | Add-UcsMacMemberBlock -From $UCS_Mac_pool_1_from -To $UCS_Mac_pool_1_to -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "Creating the MAC Pool: $($UCS_Mac_pool_2)... " -NoNewLine
$mac_pool = Add-UcsMacPool -Org $UCS_Tenant_Name -Name $UCS_Mac_pool_2 -AssignmentOrder $UCS_Mac_order -ModifyPresent
$mac_pool | Add-UcsMacMemberBlock -From $UCS_Mac_pool_2_from -To $UCS_Mac_pool_2_to -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "Creating the MAC Pool: $($UCS_Mac_pool_3)... " -NoNewLine
$mac_pool = Add-UcsMacPool -Org $UCS_Tenant_Name -Name $UCS_Mac_pool_3 -AssignmentOrder $UCS_Mac_order -ModifyPresent
$mac_pool | Add-UcsMacMemberBlock -From $UCS_Mac_pool_3_from -To $UCS_Mac_pool_3_to -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create the vNIC Templates
New-vNic-tmpl $UCS_vNIC_tmpl_1 $UCS_vNIC_tmpl_1_vlanrange $UCS_vNIC_tmpl_1_defaultvlan
New-vNic-tmpl $UCS_vNIC_tmpl_2 $UCS_vNIC_tmpl_2_vlanrange $UCS_vNIC_tmpl_2_defaultvlan
New-vNic-tmpl $UCS_vNIC_tmpl_3 $UCS_vNIC_tmpl_3_vlanrange $UCS_vNIC_tmpl_3_defaultvlan
New-vNic-tmpl $UCS_vNIC_tmpl_4 $UCS_vNIC_tmpl_4_vlanrange $UCS_vNIC_tmpl_4_defaultvlan
New-vNic-tmpl $UCS_vNIC_tmpl_5 $UCS_vNIC_tmpl_5_vlanrange $UCS_vNIC_tmpl_5_defaultvlan
New-vNic-tmpl $UCS_vNIC_tmpl_6 $UCS_vNIC_tmpl_6_vlanrange $UCS_vNIC_tmpl_6_defaultvlan
New-vNic-tmpl $UCS_vNIC_tmpl_7 $UCS_vNIC_tmpl_7_vlanrange $UCS_vNIC_tmpl_7_defaultvlan

#Create Disk Group Policies
log "Creating the Diskgroup Policy: $($UCS_Diskgroup_pol_1.Name)... " -NoNewLine
$diskgrouppol = Add-UcsLogicalStorageDiskGroupConfigPolicy @UCS_Diskgroup_pol_1 -ModifyPresent
$diskgrouppol | Add-UcsLogicalStorageDiskGroupQualifier @UCS_Diskgroup_pol_1_qual -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "Creating the Diskgroup Policy: $($UCS_Diskgroup_pol_2.Name)... " -NoNewLine
$diskgrouppol = Add-UcsLogicalStorageDiskGroupConfigPolicy @UCS_Diskgroup_pol_2 -ModifyPresent
$diskgrouppol | Add-UcsLogicalStorageDiskGroupQualifier @UCS_Diskgroup_pol_2_qual -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "Creating the Diskgroup Policy: $($UCS_Diskgroup_pol_3.Name)... " -NoNewLine
$diskgrouppol = Add-UcsLogicalStorageDiskGroupConfigPolicy @UCS_Diskgroup_pol_3 -ModifyPresent
$diskgrouppol | Add-UcsLogicalStorageDiskGroupQualifier @UCS_Diskgroup_pol_3_qual -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create a ExtMgmt IP Pool
log "Creating the CiMC Management IP Pool: $($UCS_ExMgmt_pool.Name)... " -NoNewLine
$extmgnt_pool = Add-UcsIpPool @UCS_ExMgmt_pool -ModifyPresent 
$extmgnt_pool  | Add-UcsIpPoolBlock @UCS_ExMgmt_pool_block -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create the VLAN Group for the ExtMGMT VLAN Tag
log "Creating the VLAN Group for the CiMC pool: $($UCS_vlangroup)... " -NoNewLine
Get-UcsLanCloud | Add-UcsFabricNetGroup -Name $UCS_vlangroup -ModifyPresent | Add-UcsFabricPooledVlan -Name $UCS_CIMC_vlan -ModifyPresent  | Out-Null
Add-UcsManagedObject -ModifyPresent  -ClassId MgmtInbandProfile -PropertyMap @{Dn="fabric/lan/ib-profile";DefaultVlanName="$UCS_CIMC_vlan"; Name="$UCS_vlangroup"; PoolName=$UCS_ExMgmt_pool.name } | Out-Null
log "DONE" -result -ForegroundColor GREEN

#Create the Service Profile Template
log "Creating the Service Profile Template: $($UCS_SPT_1.Name)... " -NoNewLine
$SPT = Add-UcsServiceProfile  @UCS_SPT_1 -ModifyPresent 
$SPT | Add-UcsMgmtInterface -ModifyPresent -IpV4State "pooled" -Mode "in-band" | Add-UcsMgmtVnet -Name $UCS_CIMC_vlan -ModifyPresent | Add-UcsVnicIpV4MgmtPooledAddr -Name $UCS_ExMgmt_pool.Name -ModifyPresent | Out-Null
$SPT | Add-UcsServerPoolAssignment -Name $UCS_Server_pool_1 -Qualifier $UCS_Server_pool_qual_1 -ModifyPresent | Out-Null
$SPT | Add-UcsVnic @UCS_SPT_1_vNIC_mgmt -ModifyPresent  | Out-Null
$SPT | Add-UcsVnic @UCS_SPT_1_vNIC_A -ModifyPresent | Out-Null
$SPT | Add-UcsVnic @UCS_SPT_1_vNIC_B -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "Creating the Service Profile Template: $($UCS_SPT_2.Name)... " -NoNewLine 
$SPT = Add-UcsServiceProfile  @UCS_SPT_2 -ModifyPresent 
$SPT | Add-UcsMgmtInterface -ModifyPresent -IpV4State "pooled" -Mode "in-band" | Add-UcsMgmtVnet -Name $UCS_CIMC_vlan -ModifyPresent | Add-UcsVnicIpV4MgmtPooledAddr -Name $UCS_ExMgmt_pool.Name -ModifyPresent | Out-Null
$SPT | Add-UcsServerPoolAssignment -Name $UCS_Server_pool_2 -Qualifier $UCS_Server_pool_qual_2 -ModifyPresent | Out-Null
$SPT | Add-UcsVnic @UCS_SPT_1_vNIC_mgmt -ModifyPresent  | Out-Null
$SPT | Add-UcsVnic @UCS_SPT_1_vNIC_A -ModifyPresent | Out-Null
$SPT | Add-UcsVnic @UCS_SPT_1_vNIC_B -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN

log "Creating the Service Profile Template: $($UCS_SPT_3.Name)... " -NoNewLine
$SPT = Add-UcsServiceProfile  @UCS_SPT_3 -ModifyPresent 
$SPT | Add-UcsMgmtInterface -ModifyPresent -IpV4State "pooled" -Mode "in-band" | Add-UcsMgmtVnet -Name $UCS_CIMC_vlan -ModifyPresent | Add-UcsVnicIpV4MgmtPooledAddr -Name $UCS_ExMgmt_pool.Name -ModifyPresent | Out-Null
$SPT | Add-UcsServerPoolAssignment -Name $UCS_Server_pool_3 -Qualifier $UCS_Server_pool_qual_3 -ModifyPresent | Out-Null
$SPT | Add-UcsVnic @UCS_SPT_3_PRD -ModifyPresent  | Out-Null
$SPT | Add-UcsVnic @UCS_SPT_3_DDB -ModifyPresent | Out-Null
$SPT | Add-UcsVnic @UCS_SPT_3_BCK -ModifyPresent | Out-Null
$SPT | Add-UcsVnic @UCS_SPT_3_iSCSi -ModifyPresent | Out-Null
log "DONE" -result -ForegroundColor GREEN
#endregion Main