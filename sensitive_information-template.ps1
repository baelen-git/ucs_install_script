# When running this script make sure you uncomment only 1 UCS region below.
# The script will then connect to that UCS environment en take any variables specific to that UCS Environment
# Create as many UCS regions for your customer as you want but only have 1 active.

#region UCS001
<############# UCS001 ##############
$UCS = "UCS001"
$UCS_domain = "01"
$Site = "SiteA"
$UCS_Serverports = 1..20+22..28
$PO1_desc = "VPC to switch sw001 port 2 and 4"
$PO2_desc = "VPC to switch sw001 port 3 and 5"
$UCS_ExMgmt_pool_block = @{
    From = "10.10.10.32"
    To = "10.10.10.63"
    DefGw = "10.10.10.1"
    Subnet = "255.255.254.0"
    PrimDns = "10.10.1.3"
    SecDns = "10.10.2.3"
}
###################################>
#endregion UCS001

#region UCS002
<############# UCS002 ##############
$UCS = "UCS002"
$UCS_domain = "02"
$Site = "SiteB"
$UCS_Serverports = 1..18 + 27,28
$PO1_desc = "VPC to switch sw002 port 2 and 4"
$PO2_desc = "VPC to switch sw002 port 3 and 5"
$UCS_ExMgmt_pool_block = @{
    From = "10.10.20.32"
    To = "10.10.20.63"
    DefGw = "10.10.20.1"
    Subnet = "255.255.254.0"
    PrimDns = "10.10.2.3"
    SecDns = "10.10.1.3"
}
###################################>
#endregion UCS002

$UCS_pwd = "ucsadminpwd!"
$UCS_backup_pwd = "backuppwd!"
$UCS_Tenant_Desc = "CUSTOMER_NAME Organisation"
$UCS_NTP_server_1 = "ntp1.customer.com"
$UCS_NTP_server_2 = "ntp2.customer.com"
$UCS_FTP_user="ftp.customer.com"
$UCS_alert_mailadres = "ucs@customer.com"
$UCS_Domainname = "customerdomainname"
$UCS_LdapProvider = @{
    Name = "customerdomainname.fqdn.com"
    Basedn = "DC=domain,DC=customer,DC=com"
    Rootdn = "CN=username,OU=Service,OU=Accounts,OU=group,DC=domain,DC=customer,DC=com"
    Key = "rootdn_user_pwd!"
    Vendor = "MS-AD" 
}

$UCS_Callhome = @{
    Addr="n.v.t"; 
    Contract="n.v.t"; 
    Phone="+316123456"; 
    Contact="CUSTOMER"; 
    Site="n.v.t"; 
    From="$UCS@customer.com"; 
    Customer="n.v.t"; 
    Email="ucs@customer.com"; 
    ReplyTo="$UCS@customer.com"; 
    Dn="call-home/source"
}
$UCS_Ldap_Group_name = "CN=groupname,OU=Administration,OU=Global,OU=Groups,OU=group,DC=domain,DC=customer,DC=com"

$UCS_SMTP_server = "smtp.customer.com"