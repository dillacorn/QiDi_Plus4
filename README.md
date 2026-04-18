# QiDi_Plus4

My Orca Slicer settings for the QiDi Plus4, with QiDi Box support and Klipper `gcode_macro.cfg` / `printer.cfg` adjustments that can be changed in the Fluidd UI.

## Important warnings

- Be careful when switching from high temperature filaments to lower temperature filaments.
- The cutter can leave high temp filament in the hotend. If you then feed a lower temp filament, it can jam.
- For mixed temperature swaps, manual unload and manual load is the safest method.
- If you manually extract a high temp filament that is linked to the QiDi Box, also unload it from the QiDi Box afterward.
- `Unmapped` does **not** mean the QiDi Box is disabled.
- If you want to print from a manual spool while the QiDi Box is still connected, start the print from the printer screen and disable QiDi Box there.
- `INIT_MAPPING_VALUE` is related to QiDi Box behavior.
- A separate manual spool profile is optional, but it helps prevent mistakes.

## Z-offset note

In `gcode_macro.cfg` in the Fluidd UI, the default `get_zoffset` value is:

```jinja
{% set p = (-0.15 + printer.gcode_move.homing_origin.z)|float %}
```

My current value is:

```jinja
{% set p = (-0.05 + printer.gcode_move.homing_origin.z)|float %}
```

Do not treat `-0.15` as the correct value for every machine.

Use it as a starting point only. You will likely need to adjust this yourself based on your machine, filament, bed surface, and print temperatures until first-layer squish is correct.

## Bed leveling and tramming

Only level the bed from the QiDi printer screen.

Do **not** level the bed from Fluidd.

If your bed mesh shows around `0.30` or higher out of level, re-tram the bed and recalibrate using `Z_TILT_ADJUST` plus the built-in QiDi bed reset procedure from the printer display.

For the closest tram possible, I recommend this bed tramming tool:

[QiDi Plus 4 Bed Tramming Tool](https://www.printables.com/model/1364372-qidi-plus-4-bed-tramming-tool)

Use paper to manually find an even level. The paper should have some resistance under the nozzle, but it should still move without binding hard.

I recommend running the QiDi bed reset procedure at least twice.

While doing this, apply light pressure to the center of the bed so it sits completely flat. I have noticed the bed can have a little bit of give, and using a consistent pressure point helps get a closer tram. Release pressure and re-check the paper at the center and all four corners during the procedure.

## Recommended Plus4 upgrades

I recommend printing these mods in ASA.

### HEPA filter and activated charcoal setup

- [Flush-fit HEPA filter with refillable charcoal tray](https://www.printables.com/model/1148756-qidi-plus-4-hepa-filter-flush-fit-with-refillable)
- [Activated carbon](https://www.amazon.com/Carbon-Filtration-Activated-Depot-Replacement/dp/B0DJTSD8K8)
- [HEPA filter material](https://www.amazon.com/dp/B075L64BM7)

### Exhaust and VOC / fume setup

- [Exhaust setup](https://www.thingiverse.com/thing:6794215)
- [4-inch duct line](https://www.amazon.com/iPower-Flexible-Inch-Feet-Aluminum/dp/B09B1TK2WL)
- [Adjustable 120mm fan](https://www.amazon.com/Easy-Cloud-Plug-120mm-Controller-Brushless/dp/B0BG4C9H5P)
- [120mm to 4-inch duct adapter](https://www.printables.com/model/820287-adapter-for-120mm-fan-to-4-inch-duct)  
  Print two.
- [4-inch window duct mount](https://www.amazon.com/HOXHA-Window-Ducting-Portable-Inline/dp/B0FF4JRX53?s=appliances)

### QiDi Box mods

- [Bowden tube support / bracket for QiDi Box](https://www.printables.com/model/1408927-bowden-tube-support-qidi-plus-4-bracket-for-qidi-b)
- [Jam-resistant filament guide](https://www.printables.com/model/1386069-qidi-box-jam-resistant-filament-guide/files)
- [Bowden Y-splitter for QiDi Box AMS PC4-M6](https://www.printables.com/model/1413138-bowden-y-splitter-for-qidi-box-ams-pc4-m6)
- [Extended angled spool holder for use with QiDi Box](https://www.printables.com/model/1477082-qidi-plus-4-extended-angled-spool-holder-use-with)
- [Second spool holder and QiDi Box bracket](https://www.printables.com/model/1396483-qidi-plus-4-spool-holder-and-qidi-box-bracket/files)
- [AMS Saver Filament Guide](https://www.printables.com/model/710471-ams-saver-filament-guide)
- [Qidi Box Filament Saver PC4-M6](https://www.printables.com/model/1572525-qidi-box-filament-saver-pc4-m6m10)  
  Note: remove the metal ring from the inlet first. Push the Bowden tube fully through the M6 nut and up to the entry point. While installing the part, hold the fitting release collar and press carefully to avoid bending or damaging the Bowden tube.

### Cooling and exhaust mods

- [8038 exhaust fan shroud](https://www.printables.com/model/1560525-qidi-plus-4-8038-exhaust-fan-shroud)
- [80x80x38mm fan](https://www.amazon.com/PMD2408PMB3-4-8W-80X80X38MM-2-Wire-Cooling/dp/B0F5HPTXBM)
- [Hex mainboard cover for 80mm fan](https://www.printables.com/model/1146502-qidi-plus-4-hex-mainboard-cover-for-80mm-fan-with)
- [Fan grille](https://www.amazon.com/dp/B01CU72VS4)

### 3D printed mods

- [PTFE hose anti-wear](https://www.printables.com/model/613216-ptfe-hose-anti-wear-for-bambu-lab-p1s-p2s-x1)
- [Rear chamber cover](https://www.printables.com/model/1040774-qidi-plus-4-rear-chamber-cover)
- [Hotend air duct](https://www.printables.com/model/1033699-qidi-plus-4-hotend-air-duct)
- [QiDi Plus4 plugs](https://www.printables.com/model/1161265-qidi-4-plus-plugs)
- [Cable ramp v3 screw mount](https://www.printables.com/model/1504994-qidi-plus-4-cable-ramp-v3-screw-mount)
- [Toolhead covers light](https://cults3d.com/en/3d-model/tool/qidi-plus-4-toolhead-covers-light)
- [Repositioned camera bracket](https://cults3d.com/en/3d-model/tool/qidi-plus-4-repositioned-camera-bracket)
- [Door seal with guide rails](https://www.printables.com/model/1504418-qidi-plus-4-door-seal-with-guide-rails)
- [Door seal](https://www.printables.com/model/1271100-qidi-plus-4-door-seal)
- [Simple poop box](https://www.printables.com/model/1214325-qidi-plus-4-poop-box/files)
- [Poop chute alternative](https://www.printables.com/model/1337616-qidi-plus-4-poop-chute/comments)
- [Chamber motherboard cover](https://www.printables.com/model/1040774-qidi-plus-4-rear-chamber-cover)
