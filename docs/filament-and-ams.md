# Filament handling and AMS profiles

[← README](../README.md)

The selected Orca Slicer profile must match how filament is physically supplied to the printer.

## Filament temperature swaps

* Be careful when switching from high temperature filaments to lower temperature filaments.
* The cutter can leave high temp filament in the hotend.
* Feeding lower temp filament after that can cause a jam.
* For mixed temperature swaps, manual unload and manual load is the safest method.
* If you manually extract high temp filament that is linked to the QiDi Box, also unload it from the QiDi Box afterward.

## Orca filament-source profiles

Use the printer profile that matches how filament is physically being supplied:

* `AMS MANAGED`: normal QiDi Box / AMS operation. Startup selection, loading, unloading, and tool changes are managed by the AMS workflow.
* `AMS DIRECT`: filament is physically routed through the QiDi Box, but the print uses `AMS=0` and skips AMS startup/tool-change management.
* `EXTERNAL SPOOL`: filament bypasses the QiDi Box and is fed directly from an external spool. This profile uses `AMS=0 SOURCE=EXTERNAL`.

Before using `EXTERNAL SPOOL`, unload the active filament through the QiDi Box unload process. Manually pulling filament out of the toolhead does not clear the Box synchronization state.

As a safety guard, `PRINT_START` refuses an `EXTERNAL SPOOL` print when the enabled QiDi Box still reports a synchronized slot such as `slot0`. `AMS DIRECT` is not blocked by this guard because it intentionally supports single-material printing through the Box without AMS management.

TPU-specific `AMS DIRECT - TPU` and `EXTERNAL SPOOL - TPU` variants keep the existing TPU printer-profile tuning while using the same source behavior described above.

## QiDi Box / AMS notes

* If a spool is unraveling in the QiDi Box AMS, check your rollers.
* QiDi Box essentially ruined one of my spools because a roller was not rolling smoothly.
* I resolved it by swapping rollers around. They pull out easily.
