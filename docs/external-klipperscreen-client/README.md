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

KlipperScreen should read its user config from:

```text
~/.config/KlipperScreen/KlipperScreen.conf
```

Create the config directory:

```bash
mkdir -p ~/.config/KlipperScreen
```

Copy the repo config into place from the repository root:

```bash
cp docs/external-klipperscreen-client/config/KlipperScreen/KlipperScreen.conf ~/.config/KlipperScreen/KlipperScreen.conf
```

Or, if you are already inside `docs/external-klipperscreen-client/`:

```bash
cp config/KlipperScreen/KlipperScreen.conf ~/.config/KlipperScreen/KlipperScreen.conf
```

Edit the installed config:

```bash
nano ~/.config/KlipperScreen/KlipperScreen.conf
```

Replace the placeholder Moonraker API key with your real Moonraker API key.

Do not commit your real API key to a public repo.

## Connection options

The included repo config is stored at:

```text
docs/external-klipperscreen-client/config/KlipperScreen/KlipperScreen.conf
```

The installed config should live at:

```text
~/.config/KlipperScreen/KlipperScreen.conf
```

For local LAN access, set the printer host in `~/.config/KlipperScreen/KlipperScreen.conf` to:

```text
192.168.68.118
```

For Tailscale/MagicDNS access, set the printer host to:

```text
qidi.time-puffin.ts.net
```

For HTTPS through Tailscale Serve, set the port to `443` and enable SSL in `~/.config/KlipperScreen/KlipperScreen.conf`.

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
