# QiDi Plus4

My Orca Slicer settings for the QiDi Plus4, with QiDi Box support and maintained Klipper `gcode_macro.cfg` / `printer.cfg` adjustments that can be changed in the Fluidd UI.

> [!IMPORTANT]
> **Choose the printer profile that matches the physical filament path.** Switching from high-temperature to lower-temperature filament without a proper unload can jam the hotend. An external-spool print must not start while the QiDi Box still reports a synchronized slot. See [filament handling and AMS safety](docs/filament-and-ams.md).

## Find a guide

### Printing and calibration

- **[Filament handling & AMS profiles](docs/filament-and-ams.md)**: safe temperature swaps, QiDi Box behavior, `AMS MANAGED`, `AMS DIRECT`, and `EXTERNAL SPOOL`.
- **[Z-offset & bed leveling](docs/calibration.md)**: `get_zoffset`, QiDi leveling macros, and manual bed tramming.

### Performance and controls

- **[Interfaces, performance & timelapse](docs/performance-and-interfaces.md)**: stock touchscreen, Fluidd, external KlipperScreen, optional host tuning, Obico, and timelapse settings.

### Upgrades and printed modifications

- **[Hardware, cooling & air quality](docs/hardware-and-air-quality.md)**: aluminum extruder tension bar, HEPA/charcoal filters, exhaust ducting, and cooling.
- **[QiDi Box modifications](docs/qidi-box-mods.md)**: filament guides, brackets, spool weight, and PTFE routing.
- **[Other printed modifications](docs/other-printed-mods.md)**: covers, door seals, camera brackets, and purge chute accessories.

### Additional guides

- **[External KlipperScreen client](docs/external-klipperscreen-client/README.md)**: control the printer from a separate laptop or touchscreen, without running the UI on the printer host.
- **[Corsi-Rosenthal Box](docs/CR_Box/README.md)**: supplemental room filtration, not a replacement for exhaust, HEPA/charcoal filtration, or ventilation.

## Orca Slicer printer profiles

| Profile | Filament path and behavior |
| --- | --- |
| `AMS MANAGED` | Normal QiDi Box operation, with AMS startup, loading, unloading, and tool-change management. |
| `AMS DIRECT` | Filament runs through the QiDi Box, but the print uses `AMS=0` and skips AMS startup/tool-change management. |
| `EXTERNAL SPOOL` | Filament bypasses the QiDi Box; the profile uses `AMS=0 SOURCE=EXTERNAL`. |

TPU-specific `AMS DIRECT - TPU` and `EXTERNAL SPOOL - TPU` profiles retain their existing TPU tuning.

**External-spool safety:** Unload the active filament using the QiDi Box unload procedure before feeding an external spool. Manually pulling filament from the toolhead does not reset Box synchronization. The `PRINT_START` external-spool guard rejects prints while the enabled Box reports a synchronized slot; `AMS DIRECT` is intentionally exempt.

## Optional host tuning

The [reversible Plus4 tuning script](plus4-optional-tuning.sh) provides optional controls for the stock QIDI screen stack and printer-host performance. These changes are **not required** to use the Orca profiles. See the [performance guide](docs/performance-and-interfaces.md) before applying them.

Calibration values and stability modifications documented here describe **my setup**, not universal defaults. Changing repository files does not automatically update live Fluidd/Klipper settings or installed Orca Slicer profiles.
