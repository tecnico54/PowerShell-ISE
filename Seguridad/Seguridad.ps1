$highPlan       = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  #Alto Rendimiento    
$balancedPlan   = "381b4222-f694-41f0-9685-ff5bb260df2e"  #Economizador
$cpuHighThreshold  = 60   #>=60% cambiar a alto rendimiento 
$cpuLowThreshold   = 40   #<=40% cambiar a economizador
$highDuration      = 10   #Si la CPU está >=60% durante 10s => se cambia a alto rendimiento
$lowDuration       = 20   #Si la CPU está <=40% durante 20s => se cambia a economizador
$currentPlan = (powercfg /getactivescheme).Split(' ')[3]
$highCounter = 0
$lowCounter  = 0
#Hablar:
Add-Type -AssemblyName System.Speech
$synth = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
#Bucle de cambio:
while($true){
    $cpuUsage = (Get-WmiObject -Class Win32_Processor |
                 Measure-Object -Property LoadPercentage -Average).Average
    if($cpuUsage -ge $cpuHighThreshold){
        $highCounter++
        $lowCounter = 0
        if($highCounter -eq $highDuration){
            $mensaje = "La CPU ha alcanzado un uso alto de $cpuUsage por ciento. Cambiando a alto rendimiento."
            $synth.Speak($mensaje)
        }
    }
    elseif($cpuUsage -le $cpuLowThreshold){
        $lowCounter++
        $highCounter = 0
        if($lowCounter -eq $lowDuration){
            $mensaje = "La CPU se mantiene baja en $cpuUsage por ciento. Cambiando a modo economizador."
            $synth.Speak($mensaje)
        }
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
