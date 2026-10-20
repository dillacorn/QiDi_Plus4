# Z-offset, bed leveling, and tramming

[← README](../README.md)

These are printer-specific calibration notes, not universal values.

## Z-offset note

<sub>Source / credit: [Kuo Steps for Improving Z-Offset Reliability](https://github.com/qidi-community/Plus4-Wiki/blob/main/content%2FKuo-Steps-for-Improving-Z-Offset-Reliability%2FREADME.md)</sub>

In `gcode_macro.cfg` in the Fluidd UI, the default `get_zoffset` value is:

```jinja
{% set p = (-0.15 + printer.gcode_move.homing_origin.z)|float %}
```

My current value is:

```jinja
{% set p = (-0.07 + printer.gcode_move.homing_origin.z)|float %}
```

Do not treat `-0.15` as the correct value for every machine.

Use it as a starting point only. You will likely need to adjust this yourself based on your machine, filament, bed surface, and print temperatures until first-layer squish is correct.

## Bed leveling and tramming

I no longer use the stock printer screen, so I do bed leveling from the Fluidd console using the QiDi macros.

Do **not** use the generic Fluidd bed-mesh button if it only sends:

```gcode
BED_MESH_CALIBRATE
```

Use the QiDi bed-level macros instead:

```gcode
QIDI_BED_LEVEL_60
```

for PLA / low-temp bed leveling, or:

```gcode
QIDI_BED_LEVEL_100
```

for ASA / ABS bed leveling.

These macros follow the QiDi leveling path and are safer than running a bare `BED_MESH_CALIBRATE` from Fluidd.

If your bed mesh shows around `0.30` or higher out of level, re-tram the bed and recalibrate using `Z_TILT_ADJUST` plus the QiDi bed reset / bed-level macro path.

For the closest tram possible, I recommend this bed tramming tool:

[QiDi Plus 4 Bed Tramming Tool](https://www.printables.com/model/1364372-qidi-plus-4-bed-tramming-tool)

Use paper to manually find an even level. The paper should have some resistance under the nozzle, but it should still move without binding hard.

I recommend running the QiDi bed reset procedure at least twice.

While doing this, apply light pressure to the center of the bed so it sits completely flat. I have noticed the bed can have a little bit of give, and using a consistent pressure point helps get a closer tram. Release pressure and re-check the paper at the center and all four corners during the procedure.
