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
            $iLOConfig = "Not Applicable"
            $FileLocation = "Not Applicable"
            $Factory = "Not Applicable"
            $Model = (Get-WmiObject -Class:Win32_ComputerSystem -ComputerName $Computer).Model

            if($Model -match "ProLiant"){
                $Factory = $false
                Write-Verbose "Copying Script file to C:\Temp on $Computer"
                
                #Change below source path to match your iLO Tools to be used
                Copy-Item -path "\\sourcefile_host\share\Repo\Tools\WWL\" -Destination \\$Computer\c$\Temp\ -recurse -force
                
                $Childoutput = Invoke-Command -ComputerName $Computer -ScriptBlock {
                    Set-Location C:\Temp\WWL\HPONCFG
                    $Exp = "cmd.exe /c 'C:\Temp\WWL\HPONCFG\hponcfg.exe' /all /w C:\Temp\WWL\HPONCFG\iLO_config.xml"
                    Invoke-Expression $Exp | Out-Null

                    $InProgress = $true;
                    $c=0;
                    Do{
                        if(GetProcess racadm -ea "SilentlyContinue"){
                            sleep 1; write-host "." -nonewline -ForegroundColor Red; $c=$c+1; if($c -eq 80){$c=0; write-host 'n;'}
                        }else{$InProgress = $false}

                    } While($InProgress -eq $true)

                    New-Item -Path C:\Temp\WWL\Get_Ilo_Groups_Start.xml -Force -ItemType file -Value '<!-- HPONCFG VERSION = "4.0.0.0" -->
                    <RIBCL VERSION="2.0">
                    <LOGIN USER_LOGIN="adminname" PASSWORD="password">
                    <DIR_INFO MODE="read">
                    <GET_DIR_CONFIG/>
                    </DIR_INFO>
                    </LOGIN>
                    </RIBCL>
                    '
                    $Exp1 = "cmd.exe /c 'C:\Temp\WWL\HPONCFG\hponcfg.exe' /f C:\Temp\WWL\Get_Ilo_Groups_Start.xml"
                    Invoke-Expression $Exp1

                                        $InProgress = $true;
                    $c=0;
                    Do{
                        if(GetProcess racadm -ea "SilentlyContinue"){
                            sleep 1; write-host "." -nonewline -ForegroundColor Red; $c=$c+1; if($c -eq 80){$c=0; write-host 'n;'}
                        }else{$InProgress = $false}

                    } While($InProgress -eq $true)

                }

                if((Test-Path ("\\destination_host\share\Repo\iLO_Config" + "\" + "$Env:UserName")) -eq $False){
                    New-Item -Path "\\destination_host\share\Repo\iLO_Config" -name "$Env:UserName" -ItemType "directory" | Out-Null
                }
                Copy-Item -path "\\$Computer\c$\Temp\WWL\HPONCFG\iLO_Config.xml" -Destination ("\\destination_host\share\Repo\ILO_Config" + $Env:UserName + "\" + $Computer + $timestamp + "_iLO_Config.xml")

                Remove-Item \\$Computer\c$\Temp\WWL\HPONCFG\iLO_Config.xml -force
                Remove-Item \\$Computer\c$\Temp\WWL\HPONCFG\Get_Ilo_Group_Start.xml -force
                Remove-Item \\$Computer\c$\Temp\WWL -reccurse -force

                @(foreach ($Child in $Childoutput){ if ($Child -match "OSSD"){$Factory = $true}})
                @(foreach ($Child in $Childoutput){ if ($Child -match "<"){$Child | Out-file ($Computer + "_iLO_AD_Config_Log_" + $timestamp + ".txt") -Append }})
                $iLOConfig = "Completed"
                $FileLocation = "\\destination_host\share\Repo\iLO_Config"      

            }


            $properties = [Ordered]@{ComputerName = $Computer
                            Status = 'Connected'
                            Model  = $Model
                            iLOConfig_Import = $iLOConfig
                            File_Location = $FileLocation
                            Factory_Access = $Factory
            
            }

            $obj = New-Object -TypeName PSObject -Property $properties
            Write-Output $obj
            
        }else{
            $properties = [Ordered]@{ComputerName = $Computer
                            Status = 'Not Connected'
                            Model  = $null
                            iLOConfig_Import = $null
                            File_Location = $null
                            Factory_Access = $null
            
            }

            $obj = New-Object -TypeName PSObject -Property $properties
            Write-Output $obj
        }


#Incrimenting count for interactive console text
$Count = $Count+1





}) | Export-csv ("$Env:UserName" + "_Get_iLOConfig_Log_" +$date+".csv") -NoTypeInformation

Write-Host "Script Execution Completed....Done!" -ForegroundColor Green
