#Hablar:
Add-Type -AssemblyName System.Speech
$synth = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
#Fecha actual:
$fecha = (Get-Date).ToString("dddd d 'de' MMMM 'de' yyyy", [System.Globalization.CultureInfo]::GetCultureInfo("es-CO"))
#Hora actual:
$hora = (Get-Date).ToString("hh:mm tt", [System.Globalization.CultureInfo]::GetCultureInfo("es-CO"))
#Archivos temporales:
$limpiar = Get-ChildItem -Path $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
$Espacio = [math]::Round($limpiar.Sum / 1GB, 2)
#Espacio en el disco C:
$disco = Get-PSDrive C
$espacioLibre = [math]::Round($disco.Free / 1GB, 2)
$espacioTotal = [math]::Round(($disco.Used + $disco.Free) / 1GB, 2)
$espacioUsado = $espacioTotal - $espacioLibre
$espacioPorcentaje = [math]::Round(($espacioUsado / $espacioTotal) * 100, 1)
#Temperatura de la CPU:
#Rango de temperatura:
$temperaturaBajaMax = 40
$temperaturaBajaMedia = 65
$temperaturaMediaMax = 70
$umbralTemperaturaAlta = 75
#Cargar la librería de Open Hardware Monitor:
Add-Type -Path "C:\Users\Administrador\Documents\Pruebas\OpenHardwareMonitor\OpenHardwareMonitorLib.dll"
#Crear objeto del hardware
$computer = New-Object OpenHardwareMonitor.Hardware.Computer
$computer.CPUEnabled = $true
$computer.GPUEnabled = $true
$computer.Open()
$computer.Refresh()
#Variables para almacenar temperatura y estado:
$temperaturaCPU = $null
$estado = ""
$speechText = ""
#Buscar la primera temperatura de CPU válida:
foreach($hardware in $computer.Hardware){
    $hardware.Update()
    if($hardware.HardwareType -eq 'CPU'){
        foreach($sensor in $hardware.Sensors){
            if($sensor.SensorType -eq 'Temperature' -and $sensor.Value -ne $null){
                $temperaturaCPU = [math]::Round($sensor.Value, 1)
                break
            }
        }
    }
    if($temperaturaCPU) { break }
}
#Cerrar la conexión con el hardware al finalizar:
$computer.Close()
#Clasificar temperatura:
if($temperaturaCPU -lt $temperaturaBajaMax){
        $estado = "baja"
        $recomendacion = "Está muy bien, así que no debes preocuparte."
}elseif($temperaturaCPU -lt $temperaturaBajaMedia){
        $estado = "media-baja"
        $recomendacion = "Todo está funcionando con normalidad, así que no debes preocuparte."
}elseif($temperaturaCPU -lt $temperaturaMediaMax){
        $estado = "media"
        $recomendacion = "Está estable, pero podría ser más bajo. Te recomiendo que bajes la temperatura un poco más.
        pero el CPU no está muy exigido. Posible problema: pasta térmica deteriorada o polvo en el disipador. 
        Revisa el hardware físico."
}elseif($temperaturaCPU -lt $umbralTemperaturaAlta){
        $estado = "media-alta"
         $recomendacion = "¡Advertencia!. Debrías bajar más la temperatura."
}else{
        $estado = "alta"
         $recomendacion = "¡Atención!. Deberías comprar más refrigeración, 
         pero si tienes 3 o más refrigeración, entonces, deberías cambiar el stock, si tienes uno"
}
#La Carga de la CPU:
$cpuLoad = Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty LoadPercentage
#Obtener uso de la memoria RAM:
$ram = Get-WmiObject -Class Win32_OperatingSystem
$ramTotal = [math]::round($ram.TotalVisibleMemorySize / 1MB, 2)
$ramLibre = [math]::round($ram.FreePhysicalMemory / 1MB, 2)
$ramUsada = $ramTotal - $ramLibre
$ramPorcentaje = [math]::round(($ramUsada / $ramTotal) * 100, 1)
#Aproximación de consumo de energía (en watts) basados en la carga:
#Estos valores son solo ejemplos y dependen del hardware:
$cpuPowerConsumption = $cpuLoad * 0.5  
$gpuPowerConsumption = $gpuLoad * 0.8  
$ramPowerConsumption = $ramPorcentaje * 0.1 
#Calcular consumo total estimado:
$totalPowerConsumption = $cpuPowerConsumption + $gpuPowerConsumption + $ramPowerConsumption
#Mensaje principal:
$mensaje = "¡Bienvenido!, Knower Tec.
            Hoy es $fecha, la hora es $hora,
            tus archivos temporales ocupan $Espacio gigabytes,
            el almacenamiento del disco C es de $espacioLibre gigabytes, 
            tienes $espacioTotal gigabytes de espacio libre en el disco C,
            la temperatura de tu CPU es de $temperaturaCPU grados Celsius, el estado es: $estado, $recomendacion
            la carga de la CPU es del $cpuLoad%, el uso de la memoria ram es: $ramPorcentaje%, 
            el consumo de watts del la fuente de poder es de $totalPowerConsumption%.
            Y ten en mente esto, ¡Siempre!
            1. Sé valiente y bondadoso, y todo saldrá bien.
            2. El pensamiento no te define; lo hacen tus acciones.
            3. Solo sé tú mismo.
            4. Incluso los sistemas más complejos necesitan reiniciarse. Tómate tu tiempo.
            5. Cada día es una nueva línea en tu código de vida. Compílalo con amor.
            6. Tu valor no depende de tu velocidad, sino de tu persistencia."
#Análisis final de estado general:
$problemaDetectado = ""
#Análisis de CPU:
if($temperaturaCPU -ge $umbralTemperaturaAlta){
   $problemaDetectado = "Estado crítico, temperatura de la CPU alta. $recomendacion"
}
elseif($temperaturaCPU -ge $temperaturaMediaMax){
       $problemaDetectado = "La temperatura de la CPU está fuera de lo ideal. $recomendacion"
}
#Análisis de carga de CPU:
if($cpuLoad -ge 85){
    $problemaDetectado = "$problemaDetectado La carga de la CPU está demasiado alta, 
                            sería conveniente optimizar los procesos."
}
#Análisis de uso de memoria RAM:
if($ramPorcentaje -ge 85){
    $problemaDetectado = "$problemaDetectado El uso de la memoria RAM es muy alto, podría afectar el rendimiento. 
                          Considera cerrar algunas aplicaciones que esten en segundo plano."
}
#Análisis de espacio en el disco C:
if($espacioPorcentaje -ge 97){
    $problemaDetectado = "¡Cuidado! El disco C está casi lleno. Sería recomendable liberar espacio."
}
#Análisis final:
if($problemaDetectado){
    $mensajeFinal = "Problemas detectados: $problemaDetectado"
}else{
    $mensajeFinal = "No hay ningun problema, tu PC está en **buen estado**. Todo parece estar funcionando correctamente."
}
#Cambio de voz:
$synth.SelectVoice("Microsoft Laura Desktop")
#Hablar el mensaje:
$synth.Speak($mensaje)
$synth.Speak($mensajeFinal)
