#Hablar:
Add-Type -AssemblyName System.Speech
$synth = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
#Fecha y hora actual:
$fecha = (Get-Date).ToString("dddd d 'de' MMMM 'de' yyyy", [System.Globalization.CultureInfo]::GetCultureInfo("es-CO"))
$hora = (Get-Date).ToString("hh:mm tt", [System.Globalization.CultureInfo]::GetCultureInfo("es-CO"))
#Archivos temporales:
$limpiar = Get-ChildItem -Path $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
$Espacio = [math]::Round($limpiar.Sum / 1GB, 2)
#Espacio en el disco C:
$disco = Get-PSDrive C
$espacioLibre = [math]::Round($disco.Free / 1GB, 2)
$espacioTotal = [math]::Round(($disco.Used + $disco.Free) / 1GB, 2)
#Temperatura de la CPU:
$temperaturaBajaMax = 40
$temperaturaBajaMedia = 65
$temperaturaMediaMax = 70
$umbralTemperaturaAlta = 75
#Cargar la librería de Open Hardware Monitor:
Add-Type -Path "C:\Users\Administrador\Documents\Pruebas\OpenHardwareMonitor\OpenHardwareMonitorLib.dll"
$computer = New-Object OpenHardwareMonitor.Hardware.Computer
$computer.CPUEnabled = $true
$computer.GPUEnabled = $true
$computer.Open()
$computer.Refresh()
# Obtener temperatura de la CPU:
$temperaturaCPU = $null
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
#Clasificar temperatura:
if($temperaturaCPU -lt $temperaturaBajaMax){
    $estado = "baja"
    $recomendacion = "Está muy bien, no necesitas preocuparte."
}elseif($temperaturaCPU -lt $temperaturaBajaMedia){
    $estado = "media-baja"
    $recomendacion = "Todo está funcionando con normalidad."
}elseif($temperaturaCPU -lt $temperaturaMediaMax){
    $estado = "media"
    $recomendacion = "Está estable, pero podría ser más bajo."
}elseif($temperaturaCPU -lt $umbralTemperaturaAlta){
    $estado = "media-alta"
}else{
    $estado = "alta"
}
#Carga de la CPU:
$cpuLoad = Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty LoadPercentage
#Carga y consumo de la GPU (si está presente):
$gpuLoad = 0
$gpuMessage = "No se detecta una tarjeta gráfica dedicada, solo tienes gráficos integrados."
$gpu = Get-WmiObject -Namespace "root\cimv2" -Class Win32_VideoController | Select-Object -First 1
if($gpu){
    $gpuName = $gpu.Name
    if($gpuName -match "Intel"){
        $gpuLoad = 0
        $gpuMessage = "Solo tienes gráficos integrados (Intel)."
    }else{
        $gpuLoad = 50  
        $gpuMessage = "Se detectó una tarjeta gráfica dedicada: $gpuName. Carga: $gpuLoad%. Consumo estimado: $gpuLoad%."
    }
}
#Uso de la memoria RAM:
$ramInstalada = Get-WmiObject -Class Win32_PhysicalMemory
$ramTotal = [math]::Round(($ramInstalada | Measure-Object -Property Capacity -Sum).Sum / 1GB)
$ram = Get-WmiObject -Class Win32_OperatingSystem
$ramLibre = [math]::Round($ram.FreePhysicalMemory / 1024 / 1024, 2)
$ramUsada = [math]::Round($ramTotal - $ramLibre, 2)
$ramPorcentaje = [math]::Round(($ramUsada / $ramTotal) * 100, 1)
#Consumo de energía estimado (en watts):
$cpuPowerConsumption = $cpuLoad * 0.5  
$gpuPowerConsumption = $gpuLoad * 0.8  
$ramPowerConsumption = $ramPorcentaje * 0.1  
$totalPowerConsumption = $cpuPowerConsumption + $gpuPowerConsumption + $ramPowerConsumption
#Mensaje:
$mensaje = "¡Bienvenido!, Knower Tec.
            Hoy es $fecha, la hora es $hora. Los archivos temporales ocupan $Espacio GigaBytes. 
            El disco C tiene $espacioLibre GigaBytes y $espacioTotal GigaBytes libres. 
            La temperatura de la CPU es de $temperaturaCPU°C, estado: $estado, $recomendacion. 
            Carga de CPU: $cpuLoad%. $gpuMessage 
            Tienes $ramTotal GigaBytes de memoria RAM y un uso del $ramPorcentaje%. 
            Consumo total estimado de la fuente de poder: $totalPowerConsumption watts."
#Análisis de posibles problemas:
$problemaDetectado = ""
if($temperaturaCPU -ge $umbralTemperaturaAlta){
    $problemaDetectado = "¡Alerta! La temperatura de la CPU está muy alta, 
     recomendación: comprar más ventiradores, limites: 3 o más, 
     o actualizar tu disipador, (si tienes Stock)."
}
elseif($temperaturaCPU -ge $temperaturaMediaMax){
       $problemaDetectado = "¡Advertencia! la temperatura de la CPU está fuera de lo ideal, 
        deberías reducir la temperatura, Haciendo una configuración en el Bios,
         o actualizar tu disipador, (si tienes Stock)."
}
if($cpuLoad -ge 85){
    $problemaDetectado += "La carga de la CPU es demasiado alta."
}
if($ramPorcentaje -ge 85){
    $problemaDetectado += "El uso de la memoria RAM es muy alto."
}
if($espacioPorcentaje -ge 97){
    $problemaDetectado += "El disco C está casi lleno."
}
if($Espacio -ge 5){
    $problemaDetectado += "Te recomiendo eliminar los archivos temporales."
}
#Mensaje final de estado general:
if($problemaDetectado){
    $mensajeFinal = "Problemas detectados: $problemaDetectado"
}else{
    $mensajeFinal = "Todo está en buen estado."
}
#Diagnóstico final si NO hay problemas:
$mensajesEstadoOK = @(
        "Tu PC está tan fresca... que los pingüinos la están alquilando.",
        "Está todo tan bien que hasta el antivirus se fue de vacaciones.",
        "Tu computadora está tan rápida... que ya llegó al 2026.",
        "No encontré problemas, pero encontré un archivo bailando de la felicidad.",
        "Tu computadora está tan sana... que hasta se puso a hacer ejercicio.",
        "La temperatura está tan baja que el procesador pidió una cobija.",
        "Todo está bien... pero tu teclado me pidió vacaciones.",
        "Todo está perfecto... ahora solo falta que tú también descanses."
)
#Mensajes motivacionales:
$mensajesMotivacionales = @(
        "Siempre recuerda esto: los sistemas complejos también necesitan descanso. Tú también mereces un respiro.",
        "Tu constancia es tu mejor herramienta. ¡Sigue adelante, lo estás haciendo bien!",
        "Incluso si hoy parece lento, estás avanzando. Un paso a la vez, como en un buen script.",
        "Eres capaz de grandes cosas. Cada línea que escribes es un paso más hacia tu meta.",
        "No olvides reiniciar tu mente de vez en cuando. ¡Recarga tus energías!",
        "El conocimiento no se fragmenta, se compila. Sigue aprendiendo sin miedo.",
        "Incluso los errores son parte del código que te hacen crecer.",
        "Siempre puedes optimizar tu código… y tu vida también.",
        "Tu potencial no tiene límites, como un bucle bien diseñado.",
        "No hay error crítico que no puedas corregir. ¡Confía en tu lógica!",
        "Sé valiente y bondadoso, y todo saldrá bien.",
        "El pensamiento no te define; lo hacen tus acciones.",
        "Solo sé tú mismo.",
        "Cada día es una nueva línea en tu código de vida. Compílalo con amor.",
        "Tu valor no depende de tu velocidad, sino de tu persistencia."
)
#Selecciona uno al azar:
$estadoFinal = Get-Random -InputObject $mensajesEstadoOK
$motivacional = Get-Random -InputObject $mensajesMotivacionales
#Si no hay problemas, usar diagnóstico aleatorio positivo:
if (-not $problemaDetectado) {
    $mensajeFinal = "$estadoFinal"
}
#Hablar el mensaje:
$synth.Speak($mensaje)
$synth.Speak($mensajeFinal)
$synth.Speak($motivacional)
