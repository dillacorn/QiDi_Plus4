# External KlipperScreen Client

This guide shows how to run KlipperScreen from a separate laptop or desktop instead of running it on the QiDi Plus4 host board.

The goal is to keep the Plus4 focused on Klipper, Moonraker, Fluidd, and webcam streaming while moving the KlipperScreen UI load to another device.

## Why run KlipperScreen externally?

The QiDi Plus4 host board has limited overhead. Running extra UI software directly on the printer can increase host CPU load and may contribute to Klipper communication instability or MCU timeout issues.

Running KlipperScreen on another device avoids that problem:

```text
Printer host:
- Klipper
- Moonraker
- Fluidd
- webcamd / mjpg-streamer

External laptop:
- KlipperScreen UI
```

This does not replace Fluidd. It provides a compact touchscreen-style control interface that connects to Moonraker remotely.

## Tested setup

```text
Printer: QiDi Plus4
Printer Moonraker address: qidi.time-puffin.ts.net:7125
Client device: Arch Linux laptop
KlipperScreen installed on: external laptop only
```

Do not install or enable this KlipperScreen setup on the Plus4 host board.

## Install KlipperScreen on Arch Linux

```bash
sudo pacman -S klipperscreen
```

The Arch package installs KlipperScreen under:

```text
/opt/klipperscreen/
```

Run it manually with:

```bash
cd /opt/klipperscreen
python screen.py
```

## KlipperScreen config path

Create the config directory:

```bash
mkdir -p ~/.config/KlipperScreen
```

Edit the config:

```bash
nano ~/.config/KlipperScreen/KlipperScreen.conf
```

## Example config

Replace `YOUR_REAL_API_KEY_HERE` with your Moonraker API key.

Do not commit your real API key to a public repo.

```ini
[main]
default_printer: Plus4
show_cursor: True
keyboard_navigation: True

[printer Plus4]
moonraker_host: qidi.time-puffin.ts.net
moonraker_port: 7125
moonraker_ssl: False
moonraker_api_key: YOUR_REAL_API_KEY_HERE
move_distances: 0.1, 1, 5, 10, 25, 50

# Force useful laptop menu entries
[menu __main move]
name: Move
icon: move
panel: move

[menu __main home_all]
name: Home All
icon: home
method: printer.gcode.script
params: {"script":"G28"}

[menu __main home_x]
name: Home X
icon: home-x
method: printer.gcode.script
params: {"script":"G28 X"}

[menu __main home_y]
name: Home Y
icon: home-y
method: printer.gcode.script
params: {"script":"G28 Y"}

[menu __main home_z]
name: Home Z
icon: home-z
method: printer.gcode.script
params: {"script":"G28 Z"}
```

## LAN IP alternative

If not using the Tailscale/MagicDNS hostname, use the printer LAN IP instead:

```ini
moonraker_host: 192.168.68.118
moonraker_port: 7125
moonraker_ssl: False
```

## HTTPS / Tailscale Serve alternative

If Moonraker is being exposed through HTTPS on port 443, use this instead:

```ini
moonraker_host: qidi.time-puffin.ts.net
moonraker_port: 443
moonraker_ssl: True
```

Only use the HTTPS version if this test works:

```bash
curl -fsS https://qidi.time-puffin.ts.net/server/info | python -m json.tool
```

For direct Moonraker access on port 7125, use:

```bash
curl -fsS http://qidi.time-puffin.ts.net:7125/server/info | python -m json.tool
```

## Test Moonraker access

Run this from the external laptop:

```bash
curl -fsS http://qidi.time-puffin.ts.net:7125/server/info | python -m json.tool
curl -fsS http://qidi.time-puffin.ts.net:7125/printer/info | python -m json.tool
```

If using the LAN IP:

```bash
curl -fsS http://192.168.68.118:7125/server/info | python -m json.tool
curl -fsS http://192.168.68.118:7125/printer/info | python -m json.tool
```

If these commands fail, fix networking or Moonraker authorization before troubleshooting KlipperScreen.

## Launch KlipperScreen

```bash
cd /opt/klipperscreen
python screen.py
```

If it fails, run it with logs visible:

```bash
cd /opt/klipperscreen
python screen.py 2>&1 | tee ~/klipperscreen-run.log
```

## Notes

* This is meant to run on an external client device, not the Plus4 host board.
* Keep the real Moonraker API key out of public commits.
* `show_cursor: True` makes KlipperScreen usable with a mouse or trackpad.
* `keyboard_navigation: True` improves laptop usability.
* The custom menu entries make Move and Home controls easier to access from the main screen.
* Homing commands will move the printer. Only press Home buttons when the printer is physically clear and ready.
