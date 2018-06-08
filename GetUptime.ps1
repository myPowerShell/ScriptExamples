<#
.SYNOPSIS
 Get Uptime for list of computers in a text file

.DESCRIPTION
 This script looks for Servers.txt file in current folder or any file path supplied through command arguments
 outputs uptime for each host

 .NOTE
  File Name : GetUptime.ps1
  Author    : MyPowerShell @GitHub
  Requires  : PowerShell 2


  .ExAMPLES

  ./GetUptime.ps1 <C:\Temp\Servers.txt>


  ./GetUptime.ps1


  #>


  if($args[0] -eq $null){

      $mypath = $PSScriptRoot + "\Servers.txt"


    }
    else{

         $myppath = $args[0];

       }


$Computers = Get-Content ($mypath) -ErrorAction Stop
$Date = Get-Date -Format "yyyyMMddhhmmss"

Write-Host "Script execution in Progress... Please wait" -ForegroundColor Yellow


@(foreach ($Computer in $Computers){

$Computer = $Computer.trim()

    if (New-CimSession -ComputerName $Computer -SessionOption (New-CimSessionOption -Protocol Dcom) -ErrorAction SilentlyContinue){

        $Objwmi = Get-WmiObject -Class "Win32_OperatingSystem" -ComputerName $Computer
        $time =  New-Timespan -Start ($Objwmi.ConvertToDateTIme($Objwmi.LastBootUpTime)) -End ($Objwmi.ConvertToDateTIme($Objwmi.LocalDateTime))


        $Properties = [Ordered] @{ ComputerName = $Computer
                                   Status = "Connected"
                                   Days = $time.Days
                                   Hours = $time.Hours
                                   Minutes = $time.Minutes
                                   Seconds = $time.Seconds
                                   }
        
        
        
        }
        else{

            Write-Verbose "Entered Disconnected Hosts Section"
            $Properties = [Ordered] @{ ComputerName = $Computer
                                   Status = "DisConnected"
                                   Days = $null
                                   Hours = $null
                                   Minutes = $null
                                   Seconds = $null
                                   }

            }


$Objoutput = New-Object -TypeName PSObject -Property $Properties
Write-output $Objoutput



      
}) | Export-Csv ("GetUptime_" + $date + ".csv") -NoTypeInformation



invoke-Item ("GetUptime_" + $date + ".csv")
