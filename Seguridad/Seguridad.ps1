$highPlan = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  #Alto Rendimiento 
$balancedPlan = "381b4222-f694-41f0-9685-ff5bb260df2e"  #Equilibrado
$cpuHighThreshold = 60  #>=60% cambiar a alto rendimiento
$cpuLowThreshold  = 40  #<=40% cambiar a equilibrado
$highDuration = 10  #Segundos seguidos con CPU alta
$lowDuration = 20  #Segundos seguidos con CPU baja
$currentPlan = (powercfg /getactivescheme).Split(' ')[3]
$highCounter = 0
$lowCounter  = 0
#Flags para hablar solo una vez:
$alreadySpokeHigh = $false
$alreadySpokeLow  = $false
#Hablar:
Add-Type -AssemblyName System.Speech
$synth = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
#Pausa inicial para no hablar apenas inicia Windows:
Start-Sleep -Seconds 80
#Bucle de monitoreo:
while($true){
    $cpuUsage = (Get-WmiObject -Class Win32_Processor |
                 Measure-Object -Property LoadPercentage -Average).Average
    if($cpuUsage -ge $cpuHighThreshold){
        $highCounter += 5
        $lowCounter = 0
        if($highCounter -ge $highDuration -and $currentPlan -ne $highPlan){
            powercfg /setactive $highPlan
            $currentPlan = $highPlan
            if(-not $alreadySpokeHigh){
                $mensaje = "CPU en $cpuUsage, Cambiando a alto rendimiento."
                $synth.Speak($mensaje)
                $alreadySpokeHigh = $true
                $alreadySpokeLow  = $false
            }
        }
    }
    elseif($cpuUsage -le $cpuLowThreshold){
        $lowCounter += 5
        $highCounter = 0
        if($lowCounter -ge $lowDuration -and $currentPlan -ne $balancedPlan){
            powercfg /setactive $balancedPlan
            $currentPlan = $balancedPlan
            if(-not $alreadySpokeLow){
                $mensaje = "CPU en $cpuUsage, Cambiando a modo equilibrado."
                $synth.Speak($mensaje)
                $alreadySpokeLow  = $true
                $alreadySpokeHigh = $false
            }
        }
    }
    else{
        $highCounter = 0
        $lowCounter  = 0
    }
    Start-Sleep -Seconds 5  #Chequeo cada 5s
}
