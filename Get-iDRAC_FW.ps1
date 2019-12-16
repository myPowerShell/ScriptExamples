<#

.Note
This is an AD-hoc script, please use as you see fit.

#>

$Computers = (Get-Content servers.txt -ErrorAction Stop)
$date = Get-Date -Format "yyyyMMddhhmmss"
$time = get-date -UFormat "%m%d%Y_%H%m%S"
$Max = $Computers.Count

Write-Host "Script execution in Progress... Please wait" -ForegroundColor Yellow
$Count = 1

@(foreach ($Computer in $Computers) {

    $Computer = $Computer.Trim()
    Write-Host ("Currently Processing Server: $Count "+"of "+ $max + "  " + $Computer)
        if (New-CimSession -ComputerName $Computer -SessionOption (New-CimSessionOption -Protocol DCOM) -ErrorAction SilentlyContinue) {
            $timestamp = get-date -UFormat "%m%d%Y_%H%m%S"
            $Model = (Get-WmiObject -Class:Win32_ComputerSystem -ComputerName $Computer).Model

            if(($Model -match "PowerEdge") -and !((Test-Path ("\\$Computer\c$\Program Files\Dell\SysMgt\idrac\racadm.exe")) -eq $False)){
                $Childoutput = Invoke-Command -ComputerName $Computer -ScriptBlock {
                    $Exp = "cmd.exe /c 'C:\Program Files\Dell\SysMgt\idrac\racadm.exe' getsysinfo -d"
                    Invoke-Expression $Exp

                    $InProgress = $true;
                    $c=0;
                    Do{
                        if(GetProcess racadm -ea "SilentlyContinue"){
                            sleep 1; write-host "." -nonewline -ForegroundColor Red; $c=$c+1; if($c -eq 80){$c=0; write-host 'n;'}
                        }else{$InProgress = $false}

                    } While($InProgress -eq $true)


                }
            }else {
                $Childoutput = $null
                $oFW = "NA"
                $oLFU = "NA"
            }


            @(foreach ($Child in $Childoutput){ if ($Child -match "Firmware Version"){$oFW=$Child; $oFW=$oFW.Split("{=}"); $oFW[1].Trim()}})
            @(foreach ($Child in $Childoutput){ if ($Child -match "Last Firmware Update"){$oLFU=$Child; $oLFU=$oLFU.Split("{=}"); $oLFU[1].Trim()}})
            
            $properties = [Ordered]@{ComputerName = $Computer
                            Status = 'Connected'
                            Model  = $Model
                            iDRAC_Firmware_Version = $oFW
                            iDRAC_Last_FW_Update = $oLFU
            
            }

            $obj = New-Object -TypeName PSObject -Property $properties
            Write-Output $obj
            
        }else{
                        $properties = [Ordered]@{ComputerName = $Computer
                            Status = 'Not Connected'
                            Model  = $null
                            iDRAC_Firmware_Version = $null
                            iDRAC_Last_FW_Update = $null
            
            }

            $obj = New-Object -TypeName PSObject -Property $properties
            Write-Output $obj
        }


#Incrimenting count for interactive console text
$Count = $Count+1





}) | Export-csv ("$Env:UserName" + "_Get_iDRAC_FW_Summary_" +$date+".csv") -NoTypeInformation

Write-Host "Script Execution Completed....Done!" -ForegroundColor Green
