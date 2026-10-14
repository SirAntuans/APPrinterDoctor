# APSoft APPrinterDoctor

Herramienta PowerShell para diagnosticar y reparar el subsistema de impresion de Windows, incluida **Microsoft Print to PDF**.

## Funciones de la version 1.0.0

- Health Check del Spooler, feature PDF, controlador, puerto, impresora y cola.
- Configuracion y arranque del servicio Spooler.
- Limpieza segura de trabajos bloqueados.
- Recreacion de Microsoft Print to PDF cuando el driver y `PORTPROMPT:` estan disponibles.
- Recuperacion profunda del componente PDF mediante deshabilitacion, reinicio y rehabilitacion.
- Logs en `%ProgramData%\APSoft\APPrinterDoctor\Logs`.
- Menu interactivo y acciones aptas para automatizacion.

## Requisitos

- Windows 10 o Windows 11.
- Windows PowerShell 5.1 o PowerShell 7.
- Ejecucion como administrador.

## Uso

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\APPrinterDoctor.ps1
```

Health Check no interactivo:

```powershell
.\APPrinterDoctor.ps1 -Action HealthCheck
```

Reparar Microsoft Print to PDF:

```powershell
.\APPrinterDoctor.ps1 -Action RepairPDF
```

Recuperacion profunda cuando el driver esta ausente o inconsistente:

```powershell
.\APPrinterDoctor.ps1 -Action RepairPDF -ForceComponentRepair
```

> La recuperacion profunda puede requerir dos reinicios. Tras cada reinicio, vuelva a ejecutar `RepairPDF` hasta obtener estado saludable.

## Codigos de salida

- `0`: operacion completada.
- `1`: error general o falta de privilegios.
- `2`: reparacion incompleta.
- `3010`: reinicio requerido.

## Seguridad

El script no descarga controladores ni ejecuta binarios externos. Utiliza cmdlets integrados de Windows y conserva logs locales.

## Licencia

MIT. Consulte [LICENSE](LICENSE).
