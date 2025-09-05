$highPlan = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  #Alto Rendimiento 
$balancedPlan = "381b4222-f694-41f0-9685-ff5bb260df2e"  #Equilibrado
$cpuHighThreshold = 60  #>=60% cambiar a alto rendimiento
$cpuLowThreshold  = 40  #<=40% cambiar a equilibrado
$highDuration = 10  #Segundos seguidos con CPU alta
$lowDuration  = 20  #Segundos seguidos con CPU baja
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
#Importar funciones de Windows para detectar pantalla completa:
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class User32{
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT{
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@
function Is-Fullscreen{
    $hWnd = [User32]::GetForegroundWindow()
    if($hWnd -eq [IntPtr]::Zero) { return $false }
    $rect = New-Object User32+RECT
    [User32]::GetWindowRect($hWnd, [ref]$rect) | Out-Null
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    return ($rect.Left -eq 0 -and $rect.Top -eq 0 -and 
            $rect.Right -eq $screen.Width -and 
            $rect.Bottom -eq $screen.Height)
}
#Bucle de monitoreo:
while($true){
    $cpuUsage = (Get-WmiObject -Class Win32_Processor |
                 Measure-Object -Property LoadPercentage -Average).Average   
    $fullscreen = Is-Fullscreen
    if($cpuUsage -ge $cpuHighThreshold){
        $highCounter += 5
        $lowCounter = 0
        if($highCounter -ge $highDuration -and $currentPlan -ne $highPlan){
            powercfg /setactive $highPlan
            $currentPlan = $highPlan
            if(-not $alreadySpokeHigh -and -not $fullscreen){
                $mensaje = "CPU en $cpuUsage%, Cambiando a alto rendimiento."
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
            if(-not $alreadySpokeLow -and -not $fullscreen){
                $mensaje = "CPU en $cpuUsage%, Cambiando a modo equilibrado."
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
