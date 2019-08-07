
#region Parameters and Variables

[CmdletBinding(PositionalBinding=$False)]
Param(
  [Parameter(Mandatory=$true)]
  [switch]$show_all 
, [Parameter(Mandatory=$true)]
  [switch]$show_expired
, [Parameter(Mandatory=$true)]
  [switch]$update_expired
,
  [Parameter(Mandatory=$true)]
  [string]$ONTAP_ClusterName = "131.211.9.87"
,
  [Parameter(Mandatory=$false)]
  [string]$ontap_user = "admin"
,
  [Parameter(Mandatory=$false)]
  [string]$ontap_pass
,
  [Parameter(Mandatory=$False)]
  [switch]$DryRun
 ,
  [Parameter(Mandatory=$False)]
  [switch]$ShowVersion
)

#General Powershell Settings
$ErrorActionPreference = "Stop"
$CurrentScriptVersion = "1.0"

#endregion Parameters and Variables


Function Connect-Ontap(){
    # Check toolkit version
    try {
        if (-Not (Get-Module DataONTAP)){ Import-Module DataONTAP -EA 'STOP' -Verbose:$false }
        if ((Get-NaToolkitVersion).CompareTo([system.version]'3.2.1') -LT 0) { throw }
    }
    catch [Exception]
        {
            log "This script requires Data ONTAP PowerShell Toolkit 3.2.1 or higher."
            return;
    }
    
    #Make sure we know which cluster we want to be connected to
	If ($Cluster.Length -eq 0) { $Cluster = ((Read-host "Enter the cluster management LIF").trim()) }
    
    #If you are not connected to this controller yet

	if ($global:CurrentNcController.Name) {
        if ($global:CurrentNcController.Name.ToLower() -match $cluster.ToLower()) {
            return $global:CurrentNcController
        }
     }

    #Make sure we have the user and password to connect to this controller
	If ($ontap_user.Length -eq 0) { $ontap_user = Read-Host "Enter username for connecting to the cluster" }
	If ($ontap_pass.Length -eq 0) { $SecurePassword = Read-Host "Enter the password for" $ontap_user -AsSecureString} else {
		$SecurePassword = New-Object -TypeName System.Security.SecureString
		$Password.ToCharArray() | ForEach-Object {$SecurePassword.AppendChar($_)}
	}
	$Credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $ontap_user, $SecurePassword
        
    #connect to the NetApp Controller
	log "Attempting connection to $Cluster"
	$ClusterConnection = Connect-NcController -name $Cluster -Credential $Credentials -https
   
    #Validate if the Connection went fine
	if (!$ClusterConnection) {
		RecordIssue "Warn"
		log "Unable to connect to NetApp cluster, please ensure all supplied information is correct and try again" -ForegroundColor Yellow
		Exit        
	}	
    
    return $ClusterConnection
}

Function Show-All(){

}

