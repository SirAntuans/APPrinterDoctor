# Plan de pruebas

## APD-001: Recuperacion completa PDF

Estado inicial:
- Spooler detenido o manual.
- Feature habilitada pero driver/impresora inconsistentes.
- `Add-Printer` devuelve `0x80070705`.

Resultado esperado:
1. Spooler automatico y en ejecucion.
2. Deshabilitar feature y devolver 3010.
3. Tras reinicio, habilitar feature y devolver 3010 si corresponde.
4. Tras segundo reinicio, validar feature, driver, `PORTPROMPT:` e impresora.

## Pruebas adicionales
- Sistema saludable: no modificar componentes.
- Cola con trabajos: limpiar y reiniciar Spooler.
- Driver presente e impresora ausente: recrear solo la impresora.
- Ejecucion sin administrador: finalizar con codigo 1.
