#requires -Version 5.1
<#
.SYNOPSIS
    APSoft APPrinterDoctor v1.0.0
.DESCRIPTION
    Diagnostica y repara componentes comunes del subsistema de impresion de Windows,
    incluida la recuperacion de Microsoft Print to PDF.
.NOTES
    Autor: Antonio Pulido / APSoft
    Requiere Windows 10/11 y privilegios de administrador.
#>

[CmdletBinding()]
param(
    [ValidateSet('Menu','HealthCheck','RepairSpooler','ClearQueue','RepairPDF','FullRepair')]
    [string]$Action = 'Menu',
    [switch]$ForceComponentRepair,
    [switch]$NoPause
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$Script:AppName = 'APPrinterDoctor'
$Script:Version = '1.0.0'
$Script:BasePath = Join-Path $env:ProgramData 'APSoft\APPrinterDoctor'
$Script:LogPath = Join-Path $Script:BasePath 'Logs'
$Script:LogFile = Join-Path $Script:LogPath ("APPrinterDoctor_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$Script:FeatureName = 'Printing-PrintToPDFServices-Features'
$Script:PdfPrinter = 'Microsoft Print to PDF'
$Script:PdfDriver = 'Microsoft Print To PDF'
$Script:PdfPort = 'PORTPROMPT:'

New-Item -ItemType Directory -Path $Script:LogPath -Force | Out-Null

function Write-APLog {
    param([Parameter(Mandatory)][string]$Message,
          [ValidateSet('INFO','OK','WARN','ERROR')][string]$Level='INFO')
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Level,$Message
    Add-Content -LiteralPath $Script:LogFile -Value $line -Encoding UTF8
    $color = switch($Level){'OK'{'Green'}'WARN'{'Yellow'}'ERROR'{'Red'}default{'Gray'}}
    Write-Host $line -ForegroundColor $color
}

function Test-APAdministrator {
    $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
    $principal=[Security.Principal.WindowsPrincipal]::new($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-APWindows {
    if ($env:OS -ne 'Windows_NT') { throw 'Esta herramienta solo es compatible con Windows.' }
    if (-not (Test-APAdministrator)) { throw 'Ejecute PowerShell como administrador.' }
    Import-Module PrintManagement -ErrorAction Stop
    Import-Module Dism -ErrorAction Stop
}

function Get-APHealthCheck {
    [CmdletBinding()] param()
    $service=Get-Service Spooler -ErrorAction SilentlyContinue
    $feature=Get-WindowsOptionalFeature -Online -FeatureName $Script:FeatureName -ErrorAction SilentlyContinue
    $driver=$null; $port=$null; $printer=$null
    if ($service -and $service.Status -eq 'Running') {
        $driver=Get-PrinterDriver -Name $Script:PdfDriver -ErrorAction SilentlyContinue
        $port=Get-PrinterPort -Name $Script:PdfPort -ErrorAction SilentlyContinue
        $printer=Get-Printer -Name $Script:PdfPrinter -ErrorAction SilentlyContinue
    }
    $queueFiles=@(Get-ChildItem "$env:SystemRoot\System32\spool\PRINTERS" -Force -ErrorAction SilentlyContinue).Count
    $items=@(
        [pscustomobject]@{Component='Spooler';Status=if($service -and $service.Status -eq 'Running'){'OK'}else{'FAIL'};Detail=if($service){"$($service.Status) / $($service.StartType)"}else{'No encontrado'}},
        [pscustomobject]@{Component='Feature Print to PDF';Status=if($feature -and $feature.State -eq 'Enabled'){'OK'}else{'FAIL'};Detail=if($feature){$feature.State}else{'No disponible'}},
        [pscustomobject]@{Component='Driver PDF';Status=if($driver){'OK'}else{'FAIL'};Detail=if($driver){$driver.Name}else{'Ausente o no accesible'}},
        [pscustomobject]@{Component='Puerto PORTPROMPT:';Status=if($port){'OK'}else{'FAIL'};Detail=if($port){$port.PortMonitor}else{'Ausente o no accesible'}},
        [pscustomobject]@{Component='Impresora PDF';Status=if($printer){'OK'}else{'FAIL'};Detail=if($printer){"$($printer.DriverName) / $($printer.PortName)"}else{'Ausente'}},
        [pscustomobject]@{Component='Cola local';Status=if($queueFiles -eq 0){'OK'}else{'WARN'};Detail="$queueFiles archivo(s) pendiente(s)"}
    )
    $overall=if($items.Status -contains 'FAIL'){'CRITICAL'}elseif($items.Status -contains 'WARN'){'WARNING'}else{'HEALTHY'}
    Write-Host "`nAPPrinterDoctor Health Check - Estado: $overall" -ForegroundColor Cyan
    $items | Format-Table -AutoSize
    foreach($item in $items){ Write-APLog "$($item.Component): $($item.Status) - $($item.Detail)" $(if($item.Status -eq 'FAIL'){'ERROR'}elseif($item.Status -eq 'WARN'){'WARN'}else{'OK'}) }
    [pscustomobject]@{Overall=$overall;Items=$items;Feature=$feature;Driver=$driver;Port=$port;Printer=$printer;Service=$service}
}

function Repair-APSpooler {
    [CmdletBinding()] param()
    Write-APLog 'Configurando Spooler en inicio automatico.'
    Set-Service Spooler -StartupType Automatic
    $svc=Get-Service Spooler
    if($svc.Status -ne 'Running'){ Start-Service Spooler; $svc.WaitForStatus('Running',[TimeSpan]::FromSeconds(15)) }
    Write-APLog 'Spooler operativo.' 'OK'
}

function Clear-APPrintQueue {
    [CmdletBinding(SupportsShouldProcess)] param()
    if($PSCmdlet.ShouldProcess('Cola local de impresion','Detener Spooler y eliminar trabajos pendientes')){
        Stop-Service Spooler -Force
        try {
            Get-ChildItem "$env:SystemRoot\System32\spool\PRINTERS" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse
            Write-APLog 'Cola de impresion limpiada.' 'OK'
        } finally { Start-Service Spooler }
    }
}

function Repair-APPrintToPDF {
    [CmdletBinding()] param([switch]$ForceComponentRepair)
    Repair-APSpooler
    $health=Get-APHealthCheck
    if($health.Printer -and $health.Driver -and $health.Port -and $health.Feature.State -eq 'Enabled'){
        Write-APLog 'Microsoft Print to PDF ya esta saludable.' 'OK'; return 0
    }
    if($health.Feature.State -ne 'Enabled'){
        Write-APLog 'Habilitando la caracteristica Microsoft Print to PDF.' 'WARN'
        $r=Enable-WindowsOptionalFeature -Online -FeatureName $Script:FeatureName -All -NoRestart
        if($r.RestartNeeded){ Write-APLog 'Reinicio requerido. Reinicie y ejecute de nuevo RepairPDF.' 'WARN'; return 3010 }
    }
    $driver=Get-PrinterDriver -Name $Script:PdfDriver -ErrorAction SilentlyContinue
    $port=Get-PrinterPort -Name $Script:PdfPort -ErrorAction SilentlyContinue
    $printer=Get-Printer -Name $Script:PdfPrinter -ErrorAction SilentlyContinue
    if($driver -and $port -and -not $printer){
        try { Add-Printer -Name $Script:PdfPrinter -DriverName $driver.Name -PortName $Script:PdfPort; Write-APLog 'Impresora Microsoft Print to PDF recreada.' 'OK'; return 0 }
        catch { Write-APLog "El driver aparece registrado, pero Add-Printer fallo: $($_.Exception.Message)" 'ERROR' }
    }
    if((-not $driver -or -not $printer) -and $ForceComponentRepair){
        Write-APLog 'Iniciando reinstalacion profunda del componente PDF.' 'WARN'
        Disable-WindowsOptionalFeature -Online -FeatureName $Script:FeatureName -NoRestart | Out-Null
        Write-APLog 'Componente deshabilitado. Reinicie, ejecute RepairPDF para habilitarlo y reinicie nuevamente.' 'WARN'
        return 3010
    }
    Write-APLog 'No se completo la reparacion. Ejecute RepairPDF con -ForceComponentRepair para reinstalar el componente.' 'WARN'
    return 2
}

function Invoke-APFullRepair {
    Repair-APSpooler
    Clear-APPrintQueue -Confirm:$false
    $code=Repair-APPrintToPDF -ForceComponentRepair:$ForceComponentRepair
    Get-APHealthCheck | Out-Null
    return $code
}

function Show-APMenu {
    do {
        Clear-Host
        Write-Host '========================================================' -ForegroundColor Cyan
        Write-Host " APSoft APPrinterDoctor v$Script:Version" -ForegroundColor Yellow
        Write-Host ' Diagnostico y reparacion de impresion para Windows' -ForegroundColor White
        Write-Host '========================================================' -ForegroundColor Cyan
        Write-Host '1. Health Check'
        Write-Host '2. Reparar Spooler'
        Write-Host '3. Limpiar cola de impresion'
        Write-Host '4. Reparar Microsoft Print to PDF'
        Write-Host '5. Recuperacion completa PDF (puede requerir reinicios)'
        Write-Host '6. Reparacion completa'
        Write-Host '0. Salir'
        $choice=Read-Host 'Seleccione una opcion'
        try {
            switch($choice){
                '1'{Get-APHealthCheck|Out-Null}
                '2'{Repair-APSpooler}
                '3'{Clear-APPrintQueue -Confirm:$false}
                '4'{Repair-APPrintToPDF|Out-Null}
                '5'{Repair-APPrintToPDF -ForceComponentRepair|Out-Null}
                '6'{Invoke-APFullRepair|Out-Null}
                '0'{return}
                default{Write-Host 'Opcion no valida.' -ForegroundColor Yellow}
            }
        } catch { Write-APLog $_.Exception.Message 'ERROR' }
        if(-not $NoPause){Read-Host 'Pulse Enter para continuar'|Out-Null}
    }while($true)
}

try {
    Assert-APWindows
    Write-APLog "Inicio de APPrinterDoctor v$Script:Version. Accion: $Action"
    $exitCode=switch($Action){
        'HealthCheck'{Get-APHealthCheck|Out-Null;0}
        'RepairSpooler'{Repair-APSpooler;0}
        'ClearQueue'{Clear-APPrintQueue -Confirm:$false;0}
        'RepairPDF'{Repair-APPrintToPDF -ForceComponentRepair:$ForceComponentRepair}
        'FullRepair'{Invoke-APFullRepair}
        default{Show-APMenu;0}
    }
    Write-APLog "Finalizado con codigo $exitCode. Log: $Script:LogFile" $(if($exitCode -eq 0){'OK'}elseif($exitCode -eq 3010){'WARN'}else{'ERROR'})
    exit $exitCode
} catch {
    Write-APLog $_.Exception.Message 'ERROR'
    exit 1
}
