# Disable-NetBIOS.ps1 

#requires -version 2 
 
<# 

.SYNOPSIS 
Disable NetBIOS Over TCP/IP Setting on one or more computers. 
 
.DESCRIPTION 
Outputs the computer name, IP address(es), Adapter Description, Current Setting and Updated setting for one or more computers. 
 
.PARAMETER ComputerName 
One or more computer names. This parameter accepts pipeline input. 
 
.PARAMETER Credential 
Specifies credentials for the WMI connection. 

.Example
.\Disable-NetBIOS.ps1 Server1 | export-csv C:\Temp\Output_.csv -NoTypeInformation
 
.EXAMPLE 
 .\Disable-NetBIOS.ps1 Server1 
 Outputs information for server1. 
 
.EXAMPLE 
.\Disable-NetBIOS.ps1 server1,server2 
 Outputs information for server1 and server2. 

.EXAMPLE 
.\Disable-NetBIOS.ps1 server1,server2 | ft
 Outputs information for server1 and server2 in tabular format 
 
.EXAMPLE 
.\Disable-NetBIOS.ps1 (Get-Content ComputerList.txt) 
 Outputs information for the computers listed in ComputerList.txt. 
 
.EXAMPLE 
PS C:\> Get-Content ComputerList.txt | Disable-NetBIOS.ps1 
Same as previous example (Outputs information for the computers listed in ComputerList.txt). 
 
.EXAMPLE 
.\Disable-NetBIOS.ps1 server1,server2 -Credential (Get-Credential) 
Outputs information for server1 and server2 using different credentials. 

#> 

param( 
    [parameter(ValueFromPipeline = $TRUE)] 
    [String[]] $ComputerName = $Env:COMPUTERNAME, 
    [System.Management.Automation.PSCredential] $Credential 
) 
 
begin { 
    $PipelineInput = (-not $PSBOUNDPARAMETERS.ContainsKey("ComputerName")) -and (-not $ComputerName) 
 
    # Outputs the computer name, NIC Description, Current NetBIOS Setting and Updated NetBIOS setting
    # every IP-enabled adapter  configured on the specified computer that's configured with 
    # an IPv4 address. 
    
    function Disable-NetBIOSAddress($computerName) { 
        $params = @{ 
            "Class"        = "Win32_NetworkAdapterConfiguration" 
            "ComputerName" = $computerName 
            "Filter"       = "IPEnabled=True" 
        } 
       
        if ( $Credential ) { $params.Add("Credential", $Credential) } 
       
        get-wmiobject @params | foreach-object {
            foreach ( $adapterAddress in $_.IPAddress ) { 
                if ( $adapterAddress -match '(\d{1,3}\.){3}\d{1,3}' ) {
                    $CurrentSetting = $_.TcpipNetbiosOptions
                    $newsetting = $_.TcpipNetbiosOptions

                    if ($_.TcpipNetbiosOptions -ne 2) {
                        $_.settcpipnetbios(2)
                        #$config = (Get-wmiobject -Class Win32_NetworkAdapterConfiguration -ComputerName $_.__SERVER -filter 'index = $_.Index') | Select-Object -Property TCPIPNetBIOSOptions
                        #$newsetting = $config
                        $newsetting = 2
                        
                    }
                    

                    new-object PSObject -property @{
                        "ComputerName" = $_.__SERVER
                        "IPAddress"    = $adapterAddress
                        "Adapter_Description"  = $_.Description
                        "Old_Setting"  = $currentsetting
                        "New_Setting"  = $newsetting
                    } | select-object ComputerName, IPAddress, Adapter_Description, Old_Setting, New_Setting
     
                    
                }
            }
        }
    }
}
         
                 
 
process { 
    if ( $PipelineInput ) { 
        Disable-NetBIOSAddress $_ 
    } 
    else { 
        $ComputerName | foreach-object { 
            Disable-NetBIOSAddress $_ 
        } 
    } 
}
  

