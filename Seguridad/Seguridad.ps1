$highPlan = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"      
$balancedPlan = "381b4222-f694-41f0-9685-ff5bb260df2e"   
$cpuHighThreshold  = 60   
$cpuLowThreshold   = 40   
$highDuration      = 10   
$lowDuration       = 20  
$currentPlan = (powercfg /getactivescheme).Split(' ')[3]
$highCounter = 0
$lowCounter = 0
while($true){
    $cpuUsage = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    if($cpuUsage -ge $cpuHighThreshold){
        $highCounter++
        $lowCounter = 0
    }
    elseif($cpuUsage -le $cpuLowThreshold){
        $lowCounter++
        $highCounter = 0
    }
    else{
        $highCounter = 0
        $lowCounter  = 0
    }
    if($highCounter -ge $highDuration -and $currentPlan -ne $highPlan){
        powercfg /setactive $highPlan
        $currentPlan = $highPlan
    }
    if($lowCounter -ge $lowDuration -and $currentPlan -ne $balancedPlan){
        powercfg /setactive $balancedPlan
        $currentPlan = $balancedPlan
    }
    Start-Sleep -Seconds 1
}
