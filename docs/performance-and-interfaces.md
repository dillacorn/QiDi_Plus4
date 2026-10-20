# Printer interfaces, performance, and timelapse

[← README](../README.md)

Optional host tuning and monitoring notes from my Plus4 setup. The stock touchscreen, Obico, and webcam services do not have to be disabled to use this project.

## Stock touchscreen / QIDI screen stack

I no longer use the stock QiDi Plus4 touchscreen.

On my setup, the stock screen / Makerbase stack kept running background processes such as `xindi` / `QIDILink-client` even when I was mainly using Fluidd. While troubleshooting repeated `MCU: Timer Too Close` and main-MCU communication shutdowns, `xindi` was one of the heavier CPU users on the printer host.

I now leave the stock screen disconnected and use Fluidd from a separate laptop / touchscreen device instead. This keeps the printer host focused on Klipper, Moonraker, Fluidd, and webcam streaming instead of also running the stock screen UI.

This is optional. If you rely on the stock screen, do not disable it.

Use the optional tuning script to disable, verify, or re-enable the stock screen / Makerbase stack:

[plus4-optional-tuning.sh](../plus4-optional-tuning.sh)

In the script menu:

* `Apply optimizations` → `Disable QIDI screen service / xindi completely`
* `Undo optimizations` → `Re-enable QIDI screen service / xindi`
* `View status` → check whether the QIDI screen / QIDILink processes are running

## External KlipperScreen client

If you want a compact touchscreen-style control UI without running KlipperScreen on the Plus4 host board, run KlipperScreen from a separate laptop or touchscreen device instead.

Guide:

[External KlipperScreen Client](external-klipperscreen-client/README.md)

This keeps the KlipperScreen UI load off the printer host while still allowing control through Moonraker.

## Performance tuning

The QiDi Community Plus4 Wiki has a system tuning guide that may help with repeatable `MCU: Timer Too Close` shutdowns.

The stability setup I currently use while avoiding `MCU: Timer Too Close` problems:

* Stock screen disconnected.
* `makerbase-client.service` disabled and masked.
* WiFi USB dongle removed.
* X/Y/Z/Z1 `run_current` reduced from my previous `1.15A` test value to `1.11A`.
* `cooling_fan` `tachometer_poll_interval` changed from `0.0015` to `0.010`.
* Printer-side Orca timelapse G-code removed.
* Fluidd is used from a separate laptop / touchscreen device.
* KlipperScreen, if used, is run externally from a separate laptop instead of on the Plus4 host.

These changes are not mandatory. They are meant to reduce host CPU load, USB/device activity, and extra mainboard stress on my setup.

* [QiDi Plus4 System Tuning Guide](https://github.com/qidi-community/Plus4-Wiki/blob/main/content/system-tuning/README.md)

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
