# QiDi_Plus4

My Orca Slicer settings for the QiDi Plus4, with QiDi Box support and maintained Klipper `gcode_macro.cfg` / `printer.cfg` adjustments that can be changed in the Fluidd UI.

## Important warnings

### Filament temperature swaps

- Be careful when switching from high temperature filaments to lower temperature filaments.
- The cutter can leave high temp filament in the hotend.
- Feeding lower temp filament after that can cause a jam.
- For mixed temperature swaps, manual unload and manual load is the safest method.
- If you manually extract high temp filament that is linked to the QiDi Box, also unload it from the QiDi Box afterward.

### Manual spool / NO AMS printing

- For manual spool printing while the QiDi Box is connected, use the `NO AMS` Orca printer profile.
- The `NO AMS` profile uses `AMS=0`, skips QiDi Box startup logic, and does not call `T0`.
- Without the `NO AMS` profile, start the print from the printer screen and disable QiDi Box there.
- A separate manual spool profile is optional, but it helps prevent mistakes.

### QiDi Box / AMS notes

- If a spool is unraveling in the QiDi Box AMS, check your rollers.
- QiDi Box essentially ruined one of my spools because a roller was not rolling smoothly.
- I resolved it by swapping rollers around. They pull out easily.

### Stock touchscreen / QIDI screen stack

I no longer use the stock QiDi Plus4 touchscreen.

On my setup, the stock screen / Makerbase stack kept running background processes such as `xindi` / `QIDILink-client` even when I was mainly using Fluidd. While troubleshooting repeated `MCU: Timer Too Close` and main-MCU communication shutdowns, `xindi` was one of the heavier CPU users on the printer host.

I now leave the stock screen disconnected and use Fluidd from a separate laptop / touchscreen device instead. This keeps the printer host focused on Klipper, Moonraker, and Fluidd instead of also running the stock screen UI.

This is optional. If you rely on the stock screen, do not disable it.

Use the optional tuning script to disable, verify, or re-enable the stock screen / Makerbase stack:

[plus4-optional-tuning.sh](https://github.com/dillacorn/QiDi_Plus4/blob/main/plus4-optional-tuning.sh)

In the script menu:

- `Apply optimizations` → `Disable QIDI screen service / xindi completely`
- `Undo optimizations` → `Re-enable QIDI screen service / xindi`
- `View status` → check whether the QIDI screen / QIDILink processes are running

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
- [(Almost) Universal Spool Weight](https://www.printables.com/model/1385589-almost-universal-spool-weight-for-qidibox-mmu-unit#required-additional-parts)  
  Note: If your spool is too light or the filament is not taut enough, you may experience feeding issues. I’ve found that adding weight to the spool can improve automatic loading success and may be necessary depending on the roll and remaining filament weight. Print 4 of these, use an M6 bolt to close off the entry hole, and fill them with 4.5 mm BBs. I recommend starting around 200–300 g total added weight, then increasing only if needed.
- [PTFE Guide Clip](https://www.printables.com/model/1462946-qidi-q2qidi-plus-4-ptfe-guide-clip/remixes)
  Note: Helps keep filament inline with extruder feeding.

### Cooling and exhaust mods

- [8038 exhaust fan shroud](https://www.printables.com/model/1560525-qidi-plus-4-8038-exhaust-fan-shroud)
- 80x80x38mm 24v 2-pin 3500-4200rpm fan
- [Hex mainboard cover for 80mm fan](https://www.printables.com/model/1146502-qidi-plus-4-hex-mainboard-cover-for-80mm-fan-with)
- [Fan grille](https://www.amazon.com/dp/B01CU72VS4)
- [80mm fan filter](https://www.amazon.com/Optimized-Computer-Airflow-Dustproof-80x80mm/dp/B07WCMKZ2S?nsdOptOutParam=true)
  Note: Keeps the dust out

### 3D printed mods

- [PTFE hose anti-wear](https://www.printables.com/model/613216-ptfe-hose-anti-wear-for-bambu-lab-p1s-p2s-x1)
- [Rear chamber cover](https://www.printables.com/model/1040774-qidi-plus-4-rear-chamber-cover)
- [Hotend air duct](https://www.printables.com/model/1033699-qidi-plus-4-hotend-air-duct)
- [QiDi Plus4 plugs](https://www.printables.com/model/1161265-qidi-4-plus-plugs)
- [Cable ramp v3 screw mount](https://www.printables.com/model/1504994-qidi-plus-4-cable-ramp-v3-screw-mount)
- [Repositioned camera bracket](https://cults3d.com/en/3d-model/tool/qidi-plus-4-repositioned-camera-bracket)
- [Door seal with guide rails](https://www.printables.com/model/1504418-qidi-plus-4-door-seal-with-guide-rails)
- [Door seal](https://www.printables.com/model/1271100-qidi-plus-4-door-seal)
- [Simple poop box](https://www.printables.com/model/1214325-qidi-plus-4-poop-box/files)
- [Poop chute alternative](https://www.printables.com/model/1337616-qidi-plus-4-poop-chute/comments)
- [Chamber motherboard cover](https://www.printables.com/model/1040774-qidi-plus-4-rear-chamber-cover)
- [Toolhead covers light](https://cults3d.com/en/3d-model/tool/qidi-plus-4-toolhead-covers-light)  
  Note: I recommend printing only the front cover and skipping the backplate. The backplate looks good, but it exposes the internal toolhead electronics more than I personally prefer, especially when printing fume-heavy materials like ASA and ABS long term. It works fine, but I do not see much practical benefit to using it.
- [Poop chute guide](https://www.printables.com/model/1019715-reloadeable-poop-bucket-for-qidi-x-plus-4/comments)  
  Note: I like the open poop chute guide from this model. I use it to catch purged filament and help it fall straight down into the bucket.

## Performance Tuning

The QiDi Community Plus4 Wiki has a system tuning guide that may help with repeatable `MCU: Timer Too Close` shutdowns.

The stability setup I currently use while avoiding `MCU: Timer Too Close` problems:

- Stock screen disconnected.
- `makerbase-client.service` disabled and masked.
- WiFi USB dongle removed.
- X/Y/Z/Z1 `run_current` reduced from my previous `1.15A` test value to `1.11A`.
- `cooling_fan` `tachometer_poll_interval` changed from `0.0015` to `0.010`.
- Printer-side Orca timelapse G-code removed.
- Fluidd is used from a separate laptop / touchscreen device.

These changes are not mandatory. They are meant to reduce host CPU load, USB/device activity, and extra mainboard stress on my setup.


- [QiDi Plus4 System Tuning Guide](https://github.com/qidi-community/Plus4-Wiki/blob/main/content/system-tuning/README.md)

The tuning script sets the printer host CPU to performance mode and adjusts CPU affinity so Klipper has less interference from other services.

I recommend doing this only after upgrading the mainboard cooling fan / board cooling setup, since performance mode keeps the host CPU running at a higher speed.

This is optional, but may help if you use webcam streaming, timelapse, Obico, or other monitoring services.

## Obico / timelapse note

I removed the printer-side timelapse G-code from my Orca Slicer printer profiles.

If you use Obico, webcam streaming, Fluidd, or any other monitoring service, I strongly recommend leaving Orca's printer-side timelapse G-code empty unless you specifically need layer-change snapshots.

In Orca Slicer:

`Printer profile > Machine G-code > Time lapse G-code`

Leave the **Time lapse G-code** box empty.

This prevents Orca from inserting `TIMELAPSE_TAKE_FRAME` into every sliced G-code file. On the QiDi Plus4, this reduces unnecessary camera/screenshot/file-writing activity during prints, lowers extra host CPU load, and may help reduce the chance of rare `MCU: Timer Too Close` shutdowns. It also avoids extra write activity on the printer's internal eMMC storage.

If you insist on using layer-change timelapse G-code, use the lighter version below instead:

```gcode
{if timelapse_type == 1} ; timelapse with wipe tower
TIMELAPSE_TAKE_FRAME
{elsif timelapse_type == 0} ; timelapse without wipe tower
TIMELAPSE_TAKE_FRAME
{endif}
```

## Clean room air / Corsi-Rosenthal Box

For extra room air filtration, I recommend adding a DIY Corsi-Rosenthal Box near the printer area.

This is not a replacement for the printer exhaust, HEPA filter, activated charcoal, or window duct setup listed above. A Corsi-Rosenthal Box is mainly for cleaning room air particles, dust, and general airborne particulate matter. Treat it as supplemental room filtration, especially when printing ASA / ABS.

Put simply, it is a cheap, easy-to-build, high-airflow DIY air purifier.

Useful resources:

- [Corsi-Rosenthal Foundation build guide](https://corsirosenthalfoundation.org/resources/how-to-build-a-corsi-rosenthal-box-usa/)
- [Scientific analysis / research video](https://www.youtube.com/watch?v=gaQTYrisieA)
- [3D printable Corsi-Rosenthal Box filter parts](https://makerworld.com/en/models/520688-corsi-rosenthal-box-filter#profileId-437127)

Box I'm planning to build: [CR_Box/README.md](https://github.com/dillacorn/QiDi_Plus4/blob/main/CR_Box/README.md)

Basic notes:

- Use MERV 13 or better filters.
- Make sure the airflow arrows on the filters point inward toward the fan.
- Add a cardboard or printed shroud on the fan outlet side if the design supports it.
- Do not point the fan directly at the printer enclosure if it causes drafts or chamber temperature instability.
- Run it during and after ASA / ABS prints as extra room air cleanup.
- For fumes, odor, and VOC reduction, keep using activated charcoal and/or exhaust ventilation.
