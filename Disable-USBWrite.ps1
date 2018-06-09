<#
.SYNOPSIS
 Update Policy Registry Keys on select Servers to Disable USB Write

.DESCRIPTION
 This script looks for Servers.txt file in current folder or takes a custom file path provided as shown in example
 outputs action summary results for review

 .NOTE
  File Name : Disable-USBWrite.ps1
  Author    : MyPowerShell @GitHub
  Requires  : PowerShell 2


  .ExAMPLES

  ./Disable-USBWrite.ps1 <C:\Temp\Servers.txt>


  ./Disable-USBWrite.ps1


  #>


  if($args[0] -eq $null){

      $mypath = $PSScriptRoot + "\Servers.txt"


    }
    else{

         $myppath = $args[0];

       }


$Computers = Get-Content ($mypath) -ErrorAction Stop
$Date = Get-Date -Format "yyyyMMddhhmmss"

Write-Host "Script execution in Progress... Please review output Action Summary details once completed" -ForegroundColor Yellow


@(foreach ($Computer in $Computers){

$Computer = $Computer.trim()

    if (New-CimSession -ComputerName $Computer -SessionOption (New-CimSessionOption -Protocol Dcom) -ErrorAction SilentlyContinue){

        $KeyName = "Deny_Write"
        $KeyValue = 1
        $CurrentVlaue = 0

        $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBasekey("LocalMachine", "$Computer")
        $RegPath = $BaseKey.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\RemovableStorageDevices\\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}", $true)
        $Regpath1 = $BaseKey.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\RemovableStorageDevices", $true)
        $RegPath2 = $BaseKey.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows", $true)

            if ($RegPath1 -eq $null){
            $RegPath2.CreateSubKey("RemovableStorageDevices") | Out-Null
            $Regpath1 = $BaseKey.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\RemovableStorageDevices", $true)             
            }

            if($RegPath -eq $null){
            $Regpath1.CreateSubkey("{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}") | Out-Null
            }

       $RegPath = $BaseKey.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\RemovableStorageDevices\\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}", $true)
       $CurrentValue = $RegPath.GetValue("Deny_Write")

       if ($CurrentValue -eq 1){
       $Properties = [Ordered]@{ComputerName = $Computer
                                Status = 'Connected'
                                Deny_USBWrite = 'Compliant'
                                }
       
       
       }else{
       
       $RegPath.SetValue($KeyName, $KeyValue, [Microsoft.Win32.RegistryValueKind]::DWORD) | Out-null
       $Properties = [Ordered]@{ComputerName = $Computer
                                Status = 'Connected'
                                Deny_USBWrite = 'Updated'
                                }
    
       
            }

        $RegPath2.Close()
        $RegPath1.Close()
        $RegPath.Close()
        $BaseKey.Close()
 
        }
        else{

            Write-Verbose "Entered Disconnected Hosts Section"
            $Properties = [Ordered]@{ComputerName = $Computer
                                Status = 'Not Connected'
                                Deny_USBWrite = $null
                                }

            }


    $Objoutput = New-Object -TypeName PSObject -Property $Properties
    Write-output $Objoutput



      
}) | Export-Csv ("$Env:UserName" + "_Disable_USBWrite_" + $date + ".csv") -NoTypeInformation


    Invoke-Item ("$Env:UserName" + "_Disable_USBWrite_" + $date + ".csv")

