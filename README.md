# APSoft APPrinterDoctor

**Professional Printing Repair Toolkit for Windows**

APPrinterDoctor es una solución de diagnóstico y recuperación desarrollada por APSoft para automatizar la detección y corrección de incidencias en el ecosistema de impresión de Windows 10 y Windows 11.

La herramienta analiza el estado de los componentes críticos del sistema de impresión, incluyendo:

- Servicio Print Spooler
- Cola de impresión
- Controladores de impresora
- Puertos de impresión
- Microsoft Print to PDF
- Características opcionales de Windows relacionadas con impresión

Mediante un motor de validación basado en estados, APPrinterDoctor identifica la causa raíz del problema y ejecuta únicamente las acciones necesarias para restaurar la funcionalidad del sistema, evitando reparaciones innecesarias o invasivas.

## Características

- ✅ Health Check completo
- ✅ Reparación automática del Spooler
- ✅ Limpieza segura de colas de impresión
- ✅ Recuperación de Microsoft Print to PDF
- ✅ Reconstrucción basada en estados
- ✅ Registro detallado de eventos y acciones
- ✅ Código de salida para automatización
- ✅ Pruebas automatizadas con Pester
- ✅ Integración con GitHub Actions
- ✅ Detección y limpieza de software de fabricantes (HP, Epson, Canon, Brother, Lexmark, Samsung, Xerox, Ricoh, Dell)
- ✅ Eliminación de drivers huérfanos sin impresora asociada
- ✅ Cierre de procesos de fabricantes antes de desinstalar
- ✅ Reporte JSON automático del Health Check como evidencia

## Casos de uso

- La impresora PDF desapareció.
- No es posible imprimir.
- El Spooler se detiene constantemente.
- Existen trabajos bloqueados en cola.
- Error al generar PDF desde aplicaciones.
- Controladores inconsistentes o dañados.
- Diagnóstico preventivo antes de desplegar estaciones de trabajo.
- Software de fabricantes (HP, Epson, Canon, etc.) que genera conflictos entre instalaciones.

## Requisitos

- Windows 10 o Windows 11.
- Windows PowerShell 5.1 o PowerShell 7.
- Ejecución como administrador.

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

Recuperación profunda cuando el driver está ausente o inconsistente:

```powershell
.\APPrinterDoctor.ps1 -Action RepairPDF -ForceComponentRepair
```

> La recuperación profunda puede requerir dos reinicios. Tras cada reinicio, vuelva a ejecutar `RepairPDF` hasta obtener estado saludable.

Escanear y limpiar software de fabricantes (HP, Epson, Canon, etc.):

```powershell
.\APPrinterDoctor.ps1 -Action CleanVendors
```

> La acción detecta aplicaciones de fabricantes relacionadas con impresión, detiene sus procesos, las lista y solicita confirmación antes de desinstalarlas. Tras la limpieza reinicia el Spooler. También puede solo escanear desde el menú (opción 8). Se recomienda ejecutar Health Check después para validar el estado del sistema.

Limpiar drivers huérfanos (instalados sin impresora asociada):

```powershell
.\APPrinterDoctor.ps1 -Action CleanDrivers
```

> Cada ejecución de `HealthCheck` exporta un reporte JSON en `%ProgramData%\APSoft\APPrinterDoctor` con el estado de todos los componentes, útil como evidencia para soporte.

**Flujo recomendado de limpieza:** `CleanVendors` → `CleanDrivers` → reinicio → `FullRepair` → `HealthCheck`.

## Códigos de salida

- `0`: operación completada.
- `1`: error general o falta de privilegios.
- `2`: reparación incompleta.
- `3010`: reinicio requerido.

## Desarrollo

### Pruebas con Pester

```powershell
Invoke-Pester -Path .\Tests
```

### Integración continua

El repositorio incluye un workflow de GitHub Actions (`.github/workflows/ci.yml`) que valida la sintaxis del script y ejecuta las pruebas Pester en Windows.

## Seguridad

El script no descarga controladores ni ejecuta binarios externos. Utiliza cmdlets integrados de Windows y conserva logs locales.

## Licencia

MIT. Consulte [LICENSE](LICENSE).
