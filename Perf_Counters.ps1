
<#
#CPU Counters
$CpuCounter = get-counter -ListSet Processor
$CpuCounter.Paths

#Memory Counters
$MemCounter = get-counter -ListSet Memory
$MemCounter.Paths

#Network Counters
$NetCounter = get-counter -ListSet "Network Adapter"
$NetCounter.Paths

#Physical Disk Counters
$PhysCounter = get-counter -ListSet PhysicalDisk
$PhysCounter.Paths

#Logical Disk Counters
$LogicalCounter = get-counter -ListSet LogicalDisk
$LogicalCounter.Paths

#>
#Example 1
$CtrList = @(
    "\System\Processor Queue Length",
    "\Memory\Pages/sec",
    "\Memory\Available MBytes",
    "\Processor(*)\% Processor Time",
    "\Network Interface(*)\Bytes Received/sec",
    "\Network Interface(*)\Bytes Sent/sec",
    "\LogicalDisk(C:)\% Free Space",
    "\LogicalDisk(*)\Avg. Disk Queue Length"
)

Get-Counter -Counter $CtrList -SampleInterval 36 -MaxSamples 6 | Export-Counter -Path C:\Temp\myperf_log.blg -FileFormat BLG -Force

# Example 2

$Counters = @(
    "\\$Computer\processor(_total)\% processor time",
    "\\$Computer\memory\% committed bytes in use",
    "\\$Computer\memory\cache faults/sec",
    "\\$Computer\physicaldisk(_total)\% disk time",
    "\\$Computer\physicaldisk(_total)\current disk queue length"
)
Get-Counter -Counter $Counters -MaxSamples 5 | ForEach-Object {
    $_.CounterSamples | ForEach-Object {
        [pscustomobject]@{
            TimeStamp = $_.TimeStamp
            Path      = $_.Path
            Value     = $_.CookedValue
        }
    }
} | Export-Csv -Path PerfMonCounters.csv -NoTypeInformation

invoke-item PerfMonCounters.csv

#Example 3


$List = (Get-Counter -ListSet "Processor Information").paths
$List += (Get-Counter -listSet "memory").paths
$List += (Get-Counter -listSet "LogicalDisk").paths
$List += (Get-Counter -listSet "PhysicalDisk").paths

Get-Counter -Counter $List -Continuous | Export-Counter -Path c:\temp\myperflog.blg
# Get-Counter -Counter $List -MaxSamples 10 -SampleInterval 1 | Export-Counter -Path c:\temp\myperflog.blg
