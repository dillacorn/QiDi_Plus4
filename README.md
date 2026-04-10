# QiDi_Plus4

My settings for my Plus4 in Orca Slicer, with QiDi Box support and Klipper `gcode_macro.cfg` / `printer.cfg` adjustments that can be modified in the Fluidd UI.

## Z-offset note

In `gcode_macro.cfg` in the Fluidd UI, the default `get_zoffset` value is:

```jinja
{% set p = (-0.15 + printer.gcode_move.homing_origin.z)|float %}
```

My current setting is:

```jinja
{% set p = (-0.05 + printer.gcode_move.homing_origin.z)|float %}
```

`-0.15` should be treated as a starting point, not a universal best value. You will likely need to manually adjust this for your own machine, filament, bed surface, and printing temperatures until first-layer squish is correct.

## Bed leveling / tramming note

Only level the bed from the QiDi printer screen.

Do not level the bed from Fluidd.

If your bed mesh is showing around `0.30` or higher out of level, I recommend re-tramming the bed and recalibrating it with `Z_TILT_ADJUST` plus the built-in QiDi bed reset procedure from the printer display.

For the closest tram possible, I recommend using this bed tramming tool:

https://www.printables.com/model/1364372-qidi-plus-4-bed-tramming-tool

Use paper to manually find an even level. The paper should have some resistance when sliding under the nozzle, but still move freely enough that it does not bind hard under the nozzle.

I recommend doing the QiDi bed reset procedure at least twice.

While doing this, put light pressure on the center of the bed to make sure the bed is sitting completely flat. I have noticed the bed can have a little bit of push / give, and to get the closest possible tram you need a consistent pressure point of contact. Release and test the paper again under the nozzle at center and all 4 corners during the procedure.

## Other Plus4 upgrades

I recommend printing these mods in ASA.

### HEPA filter + activated charcoal print

Print:
https://www.printables.com/model/1148756-qidi-plus-4-hepa-filter-flush-fit-with-refillable

Activated carbon:
https://www.amazon.com/Carbon-Filtration-Activated-Depot-Replacement/dp/B0DJTSD8K8

HEPA filter material:
https://www.amazon.com/dp/B075L64BM7

### Exhaust VOC / fume setup

Exhaust setup:
https://www.thingiverse.com/thing:6794215

4" duct line:
https://www.amazon.com/iPower-Flexible-Inch-Feet-Aluminum/dp/B09B1TK2WL

Adjustable 120mm fan:
https://www.amazon.com/Easy-Cloud-Plug-120mm-Controller-Brushless/dp/B0BG4C9H5P

120mm to 4" duct adapter (print x2):
https://www.printables.com/model/820287-adapter-for-120mm-fan-to-4-inch-duct

4" window duct mount:
https://www.amazon.com/HOXHA-Window-Ducting-Portable-Inline/dp/B0FF4JRX53?s=appliances

### 3D print mods

Rear chamber cover:
https://www.printables.com/model/1040774-qidi-plus-4-rear-chamber-cover

Hotend air duct:
https://www.printables.com/model/1033699-qidi-plus-4-hotend-air-duct

Qidi Plus4 plugs:
https://www.printables.com/model/1161265-qidi-4-plus-plugs

Cable ramp v3 screw mount:
https://www.printables.com/model/1504994-qidi-plus-4-cable-ramp-v3-screw-mount

Toolhead covers light:
https://cults3d.com/en/3d-model/tool/qidi-plus-4-toolhead-covers-light

Door seal with guide rails:
https://www.printables.com/model/1504418-qidi-plus-4-door-seal-with-guide-rails

Door seal:
https://www.printables.com/model/1271100-qidi-plus-4-door-seal

Simple poop box:
https://www.printables.com/model/1214325-qidi-plus-4-poop-box/files

Or:
https://www.printables.com/model/1337616-qidi-plus-4-poop-chute/comments

### Qidi Box mods

Bowden tube support / bracket for Qidi Box:
https://www.printables.com/model/1408927-bowden-tube-support-qidi-plus-4-bracket-for-qidi-b

Jam-resistant filament guide:
https://www.printables.com/model/1386069-qidi-box-jam-resistant-filament-guide/files

Bowden Y-splitter for Qidi Box AMS PC4-M6:
https://www.printables.com/model/1413138-bowden-y-splitter-for-qidi-box-ams-pc4-m6

Best angled spool holder for use with Qidi Box:
https://www.printables.com/model/1477082-qidi-plus-4-extended-angled-spool-holder-use-with

Second holder / spool holder and Qidi Box bracket:
https://www.printables.com/model/1396483-qidi-plus-4-spool-holder-and-qidi-box-bracket/files

### Cooling / exhaust mods

8038 exhaust fan shroud:
https://www.printables.com/model/1560525-qidi-plus-4-8038-exhaust-fan-shroud

80x80x38mm fan:
https://www.amazon.com/PMD2408PMB3-4-8W-80X80X38MM-2-Wire-Cooling/dp/B0F5HPTXBM

Hex mainboard cover for 80mm fan:
https://www.printables.com/model/1146502-qidi-plus-4-hex-mainboard-cover-for-80mm-fan-with

Fan grille:
https://www.amazon.com/dp/B01CU72VS4