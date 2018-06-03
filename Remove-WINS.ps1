# Remove-WINS.ps1 

#requires -version 2 
 
<# 
Acknowlegement:
    Modified original script Written by Bill Stewart (bstewart@iname.com) for Get-DNSandWINS

.SYNOPSIS 
Remove WINS address from one or more computers. 
 
.DESCRIPTION 
Outputs the computer name, IP address(es), SubnetMask Default Gateway, and WINS server addresses for one or more computers. 
 
.PARAMETER ComputerName 
One or more computer names. This parameter accepts pipeline input. 
 
.PARAMETER Credential 
Specifies credentials for the WMI connection. 
 
.EXAMPLE 
PS C:\> Remove-WINS server1 
Outputs information for server1. 
 
.EXAMPLE 
PS C:\> Remove-WINS server1,server2 
Outputs information for server1 and server2. 

.EXAMPLE 
PS C:\> Remove-WINS server1,server2 | ft
Outputs information for server1 and server2 in tabular format 
 
.EXAMPLE 
PS C:\> Remove-WINS (Get-Content ComputerList.txt) 
Outputs information for the computers listed in ComputerList.txt. 
 
.EXAMPLE 
PS C:\> Get-Content ComputerList.txt | Remove-WINS 
Same as previous example (Outputs information for the computers listed in ComputerList.txt). 
 
.EXAMPLE 
PS C:\> Remove-WINS server1,server2 -Credential (Get-Credential) 
Outputs information for server1 and server2 using different credentials. 


#> 
 
param( 
    [parameter(ValueFromPipeline = $TRUE)] 
    [String[]] $ComputerName = $Env:COMPUTERNAME, 
    [System.Management.Automation.PSCredential] $Credential 
) 
 
begin { 
    $PipelineInput = (-not $PSBOUNDPARAMETERS.ContainsKey("ComputerName")) -and (-not $ComputerName) 
 
    # Outputs the computer name, IP address, SubnetMask, Default Gateway and WINS settings for 
    # every IP-enabled adapter with Default Gateway configured on the specified computer that's configured with 
    # an IPv4 address. 
    function Remove-WINSAddress($computerName) { 
        $params = @{ 
            "Class"        = "Win32_NetworkAdapterConfiguration" 
            "ComputerName" = $computerName 
            "Filter"       = "IPEnabled=True" 
        } 
        if ( $Credential ) { $params.Add("Credential", $Credential) } 
        get-wmiobject @params | foreach-object { 
            foreach ( $adapterAddress in $_.IPAddress ) { 
                if ( $adapterAddress -match '(\d{1,3}\.){3}\d{1,3}' ) { 
                    
                    if ($_.WINSPrimaryServer -ne $null -or $_WINSSecondaryServer -ne $null) {
                        $_.SetWINSServer('', '')
                        $_.WINSPrimaryServer = $null
                        $_.WINSSecondaryServer = $null
                    }
                    
                    foreach ( $GatewayAddress in $_.DefaultIPGateway ) { 
                        new-object PSObject -property @{ 
                            "ComputerName"        = $_.__SERVER 
                            "IPAddress"           = $adapterAddress
                            "SubnetMask"          = $_.IPSubnet[0]
                            "GatewayAddress"      = $_.DefaultIPGateway[0] 
                            "WINSPrimaryServer"   = $_.WINSPrimaryServer 
                            "WINSSecondaryServer" = $_.WINSSecondaryServer 
                        } | select-object ComputerName, IPAddress,SubnetMask, GatewayAddress, WINSPrimaryServer, WINSSecondaryServer 
                    } 
                } 
            } 
        } 
    } 
} 
 
process { 
    if ( $PipelineInput ) { 
        Remove-WINSAddress $_ 
    } 
    else { 
        $ComputerName | foreach-object { 
            Remove-WINSAddress $_ 
        } 
    } 
}