# Changelog

## 1.2.0
- Nueva accion `CleanVendors`: deteccion y desinstalacion de software de fabricantes (HP, Epson, Canon, Brother, Lexmark, Samsung, Xerox, Ricoh, Dell) relacionado con impresion.
- Escaneo sin desinstalar desde el menu (opcion 8) y accion automatizable `CleanVendors`.
- Reinicio del Spooler tras la limpieza para recargar drivers.

## 1.1.0
- Rotación automática de logs con retención de 30 días.
- Pruebas automatizadas con Pester 5.
- Integración con GitHub Actions (CI en windows-latest).
- README profesional con casos de uso y sección de desarrollo.

## 1.0.0

- Health Check inicial.
- Reparacion del Spooler.
- Limpieza de cola.
- Recuperacion de Microsoft Print to PDF.
- Reinstalacion profunda con gestion de reinicios mediante codigo 3010.
- Logs y codigos de salida para automatizacion.
