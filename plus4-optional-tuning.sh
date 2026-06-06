#!/usr/bin/env bash
set -euo pipefail

# plus4-optional-tuning.sh
# Interactive QiDi Plus4 optional host-load tuning.
#
# Run:
#   ./plus4-optional-tuning.sh
#
# No arguments needed. The script opens a menu.

BACKUP_ROOT="/root/plus4-optional-tuning-backups"
STAMP="$(date +%Y%m%d-%H%M%S)"

DO_OLD_TUNING_DISABLE=0
DO_CPU_PERFORMANCE=0
DO_SERVICE_WEIGHTS=0
DO_STRICT_AFFINITY=0
DO_QIDI_SCREEN_DISABLE=0
DO_XINDI_LIMIT=0
DO_OBICO_LIMIT=0
DO_OBICO_STREAMING=0
DO_WIFI_DISABLE=0

XINDI_CPU_QUOTA="25%"
OBICO_CPU_QUOTA="50%"

declare -a MENU_LABELS=()
declare -a MENU_GROUPS=()
declare -a MENU_SELECTED=()
declare -a RESTART_SERVICES=()

require_root() {
    if [ "${EUID}" -ne 0 ]; then
        exec sudo bash "$0"
    fi
}

service_exists() {
    local unit="$1"

    systemctl list-unit-files --no-legend "$unit" 2>/dev/null \
        | awk '{print $1}' \
        | grep -Fxq "$unit"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local answer=""

    while true; do
        if [ "$default" = "y" ]; then
            read -r -p "$prompt [Y/n]: " answer
            answer="${answer:-y}"
        else
            read -r -p "$prompt [y/N]: " answer
            answer="${answer:-n}"
        fi

        case "$answer" in
            y|Y|yes|YES|Yes) return 0 ;;
            n|N|no|NO|No) return 1 ;;
            *) echo "Answer yes or no." ;;
        esac
    done
}

ask_value() {
    local prompt="$1"
    local default="$2"
    local answer=""

    read -r -p "$prompt [$default]: " answer
    printf '%s\n' "${answer:-$default}"
}

backup_path() {
    local src="$1"
    local dst_dir="$2"

    if [ -e "$src" ]; then
        mkdir -p "$dst_dir/$(dirname "$src")"
        cp -a "$src" "$dst_dir/$src"
    fi
}

backup_current_state() {
    local backup_dir="$BACKUP_ROOT/$STAMP"

    mkdir -p "$backup_dir"

    backup_path "/etc/systemd/system/klipper.service.d/override.conf" "$backup_dir"
    backup_path "/etc/systemd/system/moonraker.service.d/override.conf" "$backup_dir"
    backup_path "/etc/systemd/system/webcamd.service.d/override.conf" "$backup_dir"
    backup_path "/etc/systemd/system/nginx.service.d/override.conf" "$backup_dir"
    backup_path "/etc/systemd/system/makerbase-client.service" "$backup_dir"
    backup_path "/etc/systemd/system/makerbase-client.service.d/override.conf" "$backup_dir"
    backup_path "/etc/systemd/system/moonraker-obico.service.d/override.conf" "$backup_dir"
    backup_path "/etc/systemd/system/plus4-cpu-performance.service" "$backup_dir"
    backup_path "/usr/local/sbin/plus4-cpu-performance" "$backup_dir"
    backup_path "/home/mks/printer_data/config/moonraker-obico.cfg" "$backup_dir"
    backup_path "/etc/default/cpufrequtils" "$backup_dir"
    backup_path "/etc/init.d/tuning" "$backup_dir"

    echo "$backup_dir" > "$BACKUP_ROOT/latest"
    echo "Backup saved: $backup_dir"
}

add_restart_service() {
    local unit="$1"
    local existing=""

    service_exists "$unit" || return 0

    for existing in "${RESTART_SERVICES[@]}"; do
        if [ "$existing" = "$unit" ]; then
            return 0
        fi
    done

    RESTART_SERVICES+=("$unit")
}

restart_changed_services() {
    if [ "${#RESTART_SERVICES[@]}" -gt 0 ]; then
        echo
        echo "Restarting changed services:"
        printf '  %s\n' "${RESTART_SERVICES[@]}"
        systemctl restart "${RESTART_SERVICES[@]}"
    fi
}

write_if_changed() {
    local dest="$1"
    local tmp=""

    tmp="$(mktemp)"
    cat > "$tmp"

    if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
        rm -f "$tmp"
        echo "Already current: $dest"
        return 1
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$tmp" "$dest"
    rm -f "$tmp"
    echo "Updated: $dest"
    return 0
}

old_tuning_present() {
    [ -x /etc/init.d/tuning ]
}

old_tuning_enabled() {
    find /etc/rc*.d -maxdepth 1 -type l -name "S*tuning" 2>/dev/null | grep -q .
}

old_tuning_disabled() {
    if ! old_tuning_present; then
        return 0
    fi

    ! old_tuning_enabled
}

all_governors_performance() {
    local f=""
    local found=0

    for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -e "$f" ] || continue
        found=1

        if [ "$(cat "$f" 2>/dev/null)" != "performance" ]; then
            return 1
        fi
    done

    [ "$found" -eq 1 ]
}

cpu_performance_applied() {
    [ -f /etc/systemd/system/plus4-cpu-performance.service ] \
        && [ -x /usr/local/sbin/plus4-cpu-performance ] \
        && all_governors_performance
}

core_weights_applied() {
    grep -Fxq "CPUWeight=700" /etc/systemd/system/klipper.service.d/override.conf 2>/dev/null \
        && grep -Fxq "CPUWeight=80" /etc/systemd/system/moonraker.service.d/override.conf 2>/dev/null \
        && grep -Fxq "Nice=2" /etc/systemd/system/webcamd.service.d/override.conf 2>/dev/null \
        && grep -Fxq "Nice=1" /etc/systemd/system/nginx.service.d/override.conf 2>/dev/null
}

strict_affinity_applied() {
    grep -Fxq "CPUAffinity=1 2" /etc/systemd/system/klipper.service.d/override.conf 2>/dev/null \
        && grep -Fxq "CPUAffinity=3" /etc/systemd/system/moonraker.service.d/override.conf 2>/dev/null \
        && grep -Fxq "CPUAffinity=3" /etc/systemd/system/webcamd.service.d/override.conf 2>/dev/null \
        && grep -Fxq "CPUAffinity=3" /etc/systemd/system/nginx.service.d/override.conf 2>/dev/null
}

xindi_limit_applied() {
    local file="/etc/systemd/system/makerbase-client.service.d/override.conf"

    grep -Fxq "Nice=5" "$file" 2>/dev/null \
        && grep -Fxq "CPUWeight=10" "$file" 2>/dev/null \
        && grep -Fxq "CPUQuota=${XINDI_CPU_QUOTA}" "$file" 2>/dev/null \
        && grep -Fxq "CPUAffinity=0" "$file" 2>/dev/null
}

qidi_screen_disabled() {
    local enabled_state=""

    enabled_state="$(systemctl is-enabled makerbase-client.service 2>/dev/null || true)"

    if [ "$enabled_state" != "masked" ]; then
        return 1
    fi

    if systemctl is-active --quiet makerbase-client.service 2>/dev/null; then
        return 1
    fi

    ! pgrep -f '/root/xindi/build/xindi|/root/xindi/build/start.sh|/root/QIDILink-client/udp_server' >/dev/null 2>&1
}

qidi_screen_processes_running() {
    pgrep -f '/root/xindi/build/xindi|/root/xindi/build/start.sh|/root/QIDILink-client/udp_server' >/dev/null 2>&1
}

obico_limit_applied() {
    local file="/etc/systemd/system/moonraker-obico.service.d/override.conf"

    grep -Fxq "Nice=5" "$file" 2>/dev/null \
        && grep -Fxq "CPUWeight=30" "$file" 2>/dev/null \
        && grep -Fxq "CPUQuota=${OBICO_CPU_QUOTA}" "$file" 2>/dev/null
}

obico_streaming_disabled() {
    local cfg="/home/mks/printer_data/config/moonraker-obico.cfg"

    [ -f "$cfg" ] \
        && grep -Eiq '^[[:space:]]*disable_video_streaming[[:space:]]*=[[:space:]]*True[[:space:]]*$' "$cfg"
}

obico_logging_info() {
    local cfg="/home/mks/printer_data/config/moonraker-obico.cfg"

    [ -f "$cfg" ] \
        && grep -Eiq '^[[:space:]]*level[[:space:]]*=[[:space:]]*INFO[[:space:]]*$' "$cfg"
}

wifi_disable_applied() {
    local wlan_down=0
    local service_quiet=0

    if ip link show wlan0 >/dev/null 2>&1; then
        if ! ip -br link show wlan0 2>/dev/null | awk '{print $2}' | grep -q "UP"; then
            wlan_down=1
        fi
    else
        wlan_down=1
    fi

    if ! service_exists "makerbase-wlan0.service"; then
        service_quiet=1
    elif ! systemctl is-enabled --quiet makerbase-wlan0.service 2>/dev/null \
        && ! systemctl is-active --quiet makerbase-wlan0.service 2>/dev/null; then
        service_quiet=1
    fi

    [ "$wlan_down" -eq 1 ] && [ "$service_quiet" -eq 1 ]
}

apply_disable_old_tuning() {
    if ! old_tuning_present; then
        echo "Already done: old community tuning script is not installed"
        return 0
    fi

    if old_tuning_disabled; then
        echo "Already done: old community tuning boot script is disabled"
        return 0
    fi

    if command -v update-rc.d >/dev/null 2>&1; then
        update-rc.d tuning disable
        echo "Disabled: old community /etc/init.d/tuning boot script"
    else
        echo "Cannot disable old tuning automatically: update-rc.d not found"
    fi
}

undo_disable_old_tuning() {
    if ! old_tuning_present; then
        echo "Already done: old community tuning script is not installed"
        return 0
    fi

    if old_tuning_enabled; then
        echo "Already done: old community tuning boot script is enabled"
        return 0
    fi

    if command -v update-rc.d >/dev/null 2>&1; then
        update-rc.d tuning enable
        echo "Re-enabled: old community /etc/init.d/tuning boot script"
    else
        echo "Cannot re-enable old tuning automatically: update-rc.d not found"
    fi
}

install_cpu_performance_service() {
    if cpu_performance_applied; then
        echo "Already done: CPU performance governor service"
        return 0
    fi

    write_if_changed /usr/local/sbin/plus4-cpu-performance <<'EOF' || true
#!/bin/sh
set -eu

if command -v cpufreq-set >/dev/null 2>&1; then
    cpufreq-set -g performance || true
    cpufreq-set -d 1200Mhz || true
fi

for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -w "$f" ] && echo performance > "$f" || true
done
EOF

    chmod 755 /usr/local/sbin/plus4-cpu-performance

    write_if_changed /etc/systemd/system/plus4-cpu-performance.service <<'EOF' || true
[Unit]
Description=QiDi Plus4 CPU performance governor
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/plus4-cpu-performance
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable plus4-cpu-performance.service >/dev/null
    systemctl restart plus4-cpu-performance.service
}

install_core_service_weights() {
    if [ "$DO_STRICT_AFFINITY" = "1" ] && strict_affinity_applied && core_weights_applied; then
        echo "Already done: strict CPU affinity mode"
        return 0
    fi

    if [ "$DO_STRICT_AFFINITY" = "0" ] && core_weights_applied && ! strict_affinity_applied; then
        echo "Already done: core service CPU weights-only mode"
        return 0
    fi

    if [ "$DO_STRICT_AFFINITY" = "1" ]; then
        write_if_changed /etc/systemd/system/klipper.service.d/override.conf <<'EOF' || true
[Service]
CPUAccounting=true
CPUWeight=700
CPUAffinity=1 2
EOF

        write_if_changed /etc/systemd/system/moonraker.service.d/override.conf <<'EOF' || true
[Service]
CPUAccounting=true
CPUWeight=80
CPUAffinity=3
EOF

        write_if_changed /etc/systemd/system/webcamd.service.d/override.conf <<'EOF' || true
[Service]
Nice=2
CPUAccounting=true
CPUWeight=10
CPUAffinity=3
EOF

        write_if_changed /etc/systemd/system/nginx.service.d/override.conf <<'EOF' || true
[Service]
Nice=1
CPUAccounting=true
CPUWeight=30
CPUAffinity=3
EOF
    else
        write_if_changed /etc/systemd/system/klipper.service.d/override.conf <<'EOF' || true
[Service]
CPUAccounting=true
CPUWeight=700
EOF

        write_if_changed /etc/systemd/system/moonraker.service.d/override.conf <<'EOF' || true
[Service]
CPUAccounting=true
CPUWeight=80
EOF

        write_if_changed /etc/systemd/system/webcamd.service.d/override.conf <<'EOF' || true
[Service]
Nice=2
CPUAccounting=true
CPUWeight=10
EOF

        write_if_changed /etc/systemd/system/nginx.service.d/override.conf <<'EOF' || true
[Service]
Nice=1
CPUAccounting=true
CPUWeight=30
EOF
    fi

    add_restart_service "klipper.service"
    add_restart_service "moonraker.service"
    add_restart_service "webcamd.service"
    add_restart_service "nginx.service"

    systemctl daemon-reload
}

disable_qidi_screen_service() {
    if qidi_screen_disabled; then
        echo "Already done: QIDI screen service / xindi is disabled and masked"
        return 0
    fi

    systemctl disable --now makerbase-client.service >/dev/null 2>&1 || true
    systemctl mask makerbase-client.service >/dev/null 2>&1 || true

    pkill -f '/root/xindi/build/xindi' >/dev/null 2>&1 || true
    pkill -f '/root/xindi/build/start.sh' >/dev/null 2>&1 || true
    pkill -f '/root/QIDILink-client/udp_server' >/dev/null 2>&1 || true

    systemctl daemon-reload
    echo "Disabled: QIDI screen service / xindi / QIDILink stack"
}

enable_qidi_screen_service() {
    systemctl unmask makerbase-client.service >/dev/null 2>&1 || true

    if service_exists "makerbase-client.service"; then
        systemctl enable --now makerbase-client.service >/dev/null 2>&1 || true
        echo "Re-enabled: QIDI screen service / xindi stack"
    else
        echo "Cannot re-enable QIDI screen service: makerbase-client.service not found"
    fi

    systemctl daemon-reload
}

install_xindi_limit() {
    if xindi_limit_applied; then
        echo "Already done: xindi / makerbase-client limit"
        return 0
    fi

    write_if_changed /etc/systemd/system/makerbase-client.service.d/override.conf <<EOF || true
[Service]
Nice=5
CPUAccounting=true
CPUWeight=10
CPUQuota=${XINDI_CPU_QUOTA}
CPUAffinity=0
EOF

    add_restart_service "makerbase-client.service"
    systemctl daemon-reload
}

install_obico_limit() {
    if ! service_exists "moonraker-obico.service"; then
        echo "Skipping: moonraker-obico.service not found"
        return 0
    fi

    if obico_limit_applied; then
        echo "Already done: Obico CPU limit"
        return 0
    fi

    write_if_changed /etc/systemd/system/moonraker-obico.service.d/override.conf <<EOF || true
[Service]
Nice=5
CPUAccounting=true
CPUWeight=30
CPUQuota=${OBICO_CPU_QUOTA}
EOF

    add_restart_service "moonraker-obico.service"
    systemctl daemon-reload
}

patch_obico_streaming_disabled() {
    local cfg="/home/mks/printer_data/config/moonraker-obico.cfg"

    if [ ! -f "$cfg" ]; then
        echo "Skipping: $cfg not found"
        return 0
    fi

    if obico_streaming_disabled && obico_logging_info; then
        echo "Already done: Obico live video streaming disabled and logging INFO"
        return 0
    fi

    python3 - "$cfg" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()

def rebuild_sections(current_lines):
    sections = {}
    for i, line in enumerate(current_lines):
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            sections[stripped[1:-1].strip()] = i
    return sections

sections = rebuild_sections(lines)

def ensure_section(section):
    global lines, sections
    if section not in sections:
        if lines and lines[-1].strip():
            lines.append("")
        lines.append(f"[{section}]")
        sections = rebuild_sections(lines)

def set_key(section, key, value):
    global lines, sections
    ensure_section(section)

    start = sections[section] + 1
    end = len(lines)

    for _, idx in sections.items():
        if idx > sections[section]:
            end = min(end, idx)

    for i in range(start, end):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue

        current_key = stripped.split("=", 1)[0].strip().lower()
        if current_key == key.lower():
            lines[i] = f"{key} = {value}"
            return

    lines.insert(end, f"{key} = {value}")
    sections = rebuild_sections(lines)

set_key("webcam", "disable_video_streaming", "True")
set_key("logging", "level", "INFO")

path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY

    add_restart_service "moonraker-obico.service"
    echo "Updated: Obico live video streaming disabled and logging INFO"
}

patch_obico_streaming_enabled() {
    local cfg="/home/mks/printer_data/config/moonraker-obico.cfg"

    if [ ! -f "$cfg" ]; then
        echo "Skipping: $cfg not found"
        return 0
    fi

    if ! grep -Eiq '^[[:space:]]*disable_video_streaming[[:space:]]*=[[:space:]]*True[[:space:]]*$' "$cfg"; then
        echo "Already done: Obico live video streaming is enabled or not disabled by config"
        return 0
    fi

    python3 - "$cfg" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()

def rebuild_sections(current_lines):
    sections = {}
    for i, line in enumerate(current_lines):
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            sections[stripped[1:-1].strip()] = i
    return sections

sections = rebuild_sections(lines)

if "webcam" not in sections:
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    raise SystemExit(0)

start = sections["webcam"] + 1
end = len(lines)

for _, idx in sections.items():
    if idx > sections["webcam"]:
        end = min(end, idx)

for i in range(start, end):
    stripped = lines[i].strip()
    if not stripped or stripped.startswith("#") or "=" not in stripped:
        continue

    key = stripped.split("=", 1)[0].strip().lower()
    if key == "disable_video_streaming":
        lines[i] = "disable_video_streaming = False"
        break

path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY

    add_restart_service "moonraker-obico.service"
    echo "Updated: Obico live video streaming enabled"
}

disable_wifi_if_safe() {
    if wifi_disable_applied; then
        echo "Already done: Wi-Fi service/interface disabled"
        return 0
    fi

    local eth_has_ip="0"
    local ssh_iface=""

    if ip -4 addr show eth0 2>/dev/null | grep -q "inet "; then
        eth_has_ip="1"
    fi

    if [ -n "${SSH_CLIENT:-}" ]; then
        local ssh_ip
        ssh_ip="$(echo "$SSH_CLIENT" | awk '{print $1}')"
        ssh_iface="$(ip route get "$ssh_ip" 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="dev") print $(i+1); exit}')"
    fi

    if [ "$ssh_iface" = "wlan0" ]; then
        echo "Skipping Wi-Fi disable: current SSH session appears to use wlan0"
        return 0
    fi

    if [ "$eth_has_ip" != "1" ]; then
        echo "Skipping Wi-Fi disable: eth0 has no IPv4 address"
        return 0
    fi

    if service_exists "makerbase-wlan0.service"; then
        systemctl disable makerbase-wlan0.service >/dev/null 2>&1 || true
        systemctl stop makerbase-wlan0.service >/dev/null 2>&1 || true
    fi

    ip link set wlan0 down 2>/dev/null || true
    echo "Disabled: Wi-Fi service/interface"
}

undo_cpu_performance() {
    if [ ! -f /etc/systemd/system/plus4-cpu-performance.service ] && [ ! -f /usr/local/sbin/plus4-cpu-performance ]; then
        echo "Already done: CPU performance governor service is not installed"
        return 0
    fi

    systemctl disable --now plus4-cpu-performance.service >/dev/null 2>&1 || true
    rm -f /etc/systemd/system/plus4-cpu-performance.service
    rm -f /usr/local/sbin/plus4-cpu-performance
    systemctl daemon-reload

    echo "Removed: CPU performance governor service"
}

undo_core_service_weights() {
    local removed=0
    local file=""

    for file in \
        /etc/systemd/system/klipper.service.d/override.conf \
        /etc/systemd/system/moonraker.service.d/override.conf \
        /etc/systemd/system/webcamd.service.d/override.conf \
        /etc/systemd/system/nginx.service.d/override.conf; do
        if [ -f "$file" ]; then
            rm -f "$file"
            removed=1
            echo "Removed: $file"
        fi
    done

    rmdir \
        /etc/systemd/system/klipper.service.d \
        /etc/systemd/system/moonraker.service.d \
        /etc/systemd/system/webcamd.service.d \
        /etc/systemd/system/nginx.service.d \
        2>/dev/null || true

    if [ "$removed" -eq 0 ]; then
        echo "Already done: core service weights / strict affinity are not installed"
        return 0
    fi

    add_restart_service "klipper.service"
    add_restart_service "moonraker.service"
    add_restart_service "webcamd.service"
    add_restart_service "nginx.service"
    systemctl daemon-reload
}

undo_xindi_limit() {
    local file="/etc/systemd/system/makerbase-client.service.d/override.conf"

    if [ ! -f "$file" ]; then
        echo "Already done: xindi / makerbase-client limit is not installed"
        return 0
    fi

    rm -f "$file"
    rmdir /etc/systemd/system/makerbase-client.service.d 2>/dev/null || true

    add_restart_service "makerbase-client.service"
    systemctl daemon-reload
    echo "Removed: xindi / makerbase-client limit"
}

undo_obico_limit() {
    local file="/etc/systemd/system/moonraker-obico.service.d/override.conf"

    if [ ! -f "$file" ]; then
        echo "Already done: Obico CPU limit is not installed"
        return 0
    fi

    rm -f "$file"
    rmdir /etc/systemd/system/moonraker-obico.service.d 2>/dev/null || true

    add_restart_service "moonraker-obico.service"
    systemctl daemon-reload
    echo "Removed: Obico CPU limit"
}

undo_wifi_disable() {
    if service_exists "makerbase-wlan0.service"; then
        systemctl enable makerbase-wlan0.service >/dev/null 2>&1 || true
        systemctl start makerbase-wlan0.service >/dev/null 2>&1 || true
    fi

    ip link set wlan0 up 2>/dev/null || true
    echo "Re-enabled: makerbase-wlan0.service / wlan0"
}

resolve_scheduling_conflict() {
    if [ "$DO_SERVICE_WEIGHTS" = "1" ] && [ "$DO_STRICT_AFFINITY" = "1" ]; then
        echo
        echo "Scheduling mode conflict:"
        echo "You selected both scheduling modes."
        echo
        echo "Core weights only:"
        echo "  Safer. Gives Klipper priority without pinning services to fixed CPU cores."
        echo
        echo "Strict affinity:"
        echo "  More aggressive. Includes core weights and pins services to specific CPU cores."
        echo
        echo "Pick one mode."
        echo

        if ask_yes_no "Use strict CPU affinity instead of weights-only mode?" "n"; then
            DO_SERVICE_WEIGHTS=0
            DO_STRICT_AFFINITY=1
            echo "Selected scheduling mode: strict CPU affinity."
        else
            DO_SERVICE_WEIGHTS=1
            DO_STRICT_AFFINITY=0
            echo "Selected scheduling mode: core weights only."
        fi
    fi
}

resolve_qidi_screen_conflict() {
    if [ "$DO_QIDI_SCREEN_DISABLE" = "1" ] && [ "$DO_XINDI_LIMIT" = "1" ]; then
        echo
        echo "QIDI screen service conflict:"
        echo "You selected both disable and CPU-limit for the screen service."
        echo "Disable wins because a stopped/masked service cannot also be limited."
        DO_XINDI_LIMIT=0
    fi
}

render_checkbox_menu() {
    local current="$1"
    local title="$2"
    local checked
    local prefix
    local marker
    local i
    local last_group=""

    clear
    echo "$title"
    echo
    echo "All items start unchecked."
    echo "Use Up/Down or j/k to move."
    echo "Use Space or number keys to toggle."
    echo "Press Enter to continue."
    echo "Press q to go back."
    echo

    for i in "${!MENU_LABELS[@]}"; do
        if [ "${MENU_GROUPS[i]}" != "$last_group" ]; then
            last_group="${MENU_GROUPS[i]}"
            echo
            echo "== $last_group =="
        fi

        checked="[ ]"

        if [ "${MENU_SELECTED[i]}" = "1" ]; then
            checked="[x]"
        fi

        prefix="  "

        if [ "$i" -eq "$current" ]; then
            prefix="> "
        fi

        marker=$((i + 1))
        printf "%s%s %d. %s\n" "$prefix" "$checked" "$marker" "${MENU_LABELS[i]}"
    done

    echo
}

toggle_menu_item() {
    local index="$1"

    if [ "${MENU_SELECTED[index]}" = "1" ]; then
        MENU_SELECTED[index]=0
    else
        MENU_SELECTED[index]=1
    fi
}

checkbox_menu() {
    local title="$1"

    if [ ! -t 0 ]; then
        echo "Interactive mode requires a terminal."
        exit 1
    fi

    local current=0
    local key=""
    local rest=""
    local max_index
    local idx

    max_index=$((${#MENU_LABELS[@]} - 1))

    while true; do
        render_checkbox_menu "$current" "$title"

        key=""
        rest=""
        IFS= read -rsn1 key || true

        case "$key" in
            "")
                break
                ;;
            " ")
                toggle_menu_item "$current"
                ;;
            q|Q)
                return 1
                ;;
            j|J)
                if [ "$current" -lt "$max_index" ]; then
                    current=$((current + 1))
                else
                    current=0
                fi
                ;;
            k|K)
                if [ "$current" -gt 0 ]; then
                    current=$((current - 1))
                else
                    current="$max_index"
                fi
                ;;
            1|2|3|4|5|6|7|8|9)
                idx=$((key - 1))
                if [ "$idx" -le "$max_index" ]; then
                    toggle_menu_item "$idx"
                fi
                ;;
            $'\e')
                IFS= read -rsn2 -t 0.1 rest || true
                case "$rest" in
                    "[A")
                        if [ "$current" -gt 0 ]; then
                            current=$((current - 1))
                        else
                            current="$max_index"
                        fi
                        ;;
                    "[B")
                        if [ "$current" -lt "$max_index" ]; then
                            current=$((current + 1))
                        else
                            current=0
                        fi
                        ;;
                esac
                ;;
        esac
    done

    clear
    return 0
}

select_apply_options() {
    MENU_LABELS=(
        "Disable old community /etc/init.d/tuning boot script"
        "Force CPU governor to performance using this script"
        "Apply core service CPU weights only"
        "Apply strict CPU affinity instead of weights-only mode"
        "Disable QIDI screen service / xindi completely"
        "Limit QIDI screen service / xindi on CPU 0"
        "Keep Obico running but lower priority and cap CPU"
        "Disable Obico live video streaming"
        "Disable Wi-Fi service/interface if Ethernet is active"
    )

    MENU_GROUPS=(
        "Migration"
        "CPU"
        "Advanced service scheduling"
        "Advanced service scheduling"
        "QIDI screen service"
        "QIDI screen service"
        "Obico"
        "Obico"
        "Network"
    )

    MENU_SELECTED=(0 0 0 0 0 0 0 0 0)

    checkbox_menu "QiDi Plus4 Optional Tuning - Apply" || return 1

    DO_OLD_TUNING_DISABLE="${MENU_SELECTED[0]}"
    DO_CPU_PERFORMANCE="${MENU_SELECTED[1]}"
    DO_SERVICE_WEIGHTS="${MENU_SELECTED[2]}"
    DO_STRICT_AFFINITY="${MENU_SELECTED[3]}"
    DO_QIDI_SCREEN_DISABLE="${MENU_SELECTED[4]}"
    DO_XINDI_LIMIT="${MENU_SELECTED[5]}"
    DO_OBICO_LIMIT="${MENU_SELECTED[6]}"
    DO_OBICO_STREAMING="${MENU_SELECTED[7]}"
    DO_WIFI_DISABLE="${MENU_SELECTED[8]}"

    resolve_scheduling_conflict
    resolve_qidi_screen_conflict

    if [ "$DO_XINDI_LIMIT" = "1" ]; then
        XINDI_CPU_QUOTA="$(ask_value "xindi CPU quota" "$XINDI_CPU_QUOTA")"
    fi

    if [ "$DO_OBICO_LIMIT" = "1" ]; then
        OBICO_CPU_QUOTA="$(ask_value "Obico CPU quota" "$OBICO_CPU_QUOTA")"
    fi

    if [ "$DO_OLD_TUNING_DISABLE$DO_CPU_PERFORMANCE$DO_SERVICE_WEIGHTS$DO_STRICT_AFFINITY$DO_QIDI_SCREEN_DISABLE$DO_XINDI_LIMIT$DO_OBICO_LIMIT$DO_OBICO_STREAMING$DO_WIFI_DISABLE" = "000000000" ]; then
        echo "Nothing selected."
        return 1
    fi
}

select_undo_options() {
    MENU_LABELS=(
        "Re-enable old community /etc/init.d/tuning boot script"
        "Undo CPU performance governor service from this script"
        "Undo core service CPU weights and strict affinity"
        "Re-enable QIDI screen service / xindi"
        "Undo QIDI screen service / xindi systemd limit"
        "Undo Obico CPU limit"
        "Re-enable Obico live video streaming"
        "Re-enable Wi-Fi service/interface"
    )

    MENU_GROUPS=(
        "Migration"
        "CPU"
        "Advanced service scheduling"
        "QIDI screen service"
        "QIDI screen service"
        "Obico"
        "Obico"
        "Network"
    )

    MENU_SELECTED=(0 0 0 0 0 0 0 0)

    checkbox_menu "QiDi Plus4 Optional Tuning - Undo" || return 1

    DO_OLD_TUNING_DISABLE="${MENU_SELECTED[0]}"
    DO_CPU_PERFORMANCE="${MENU_SELECTED[1]}"
    DO_SERVICE_WEIGHTS="${MENU_SELECTED[2]}"
    DO_STRICT_AFFINITY=0
    DO_QIDI_SCREEN_DISABLE="${MENU_SELECTED[3]}"
    DO_XINDI_LIMIT="${MENU_SELECTED[4]}"
    DO_OBICO_LIMIT="${MENU_SELECTED[5]}"
    DO_OBICO_STREAMING="${MENU_SELECTED[6]}"
    DO_WIFI_DISABLE="${MENU_SELECTED[7]}"

    if [ "$DO_OLD_TUNING_DISABLE$DO_CPU_PERFORMANCE$DO_SERVICE_WEIGHTS$DO_QIDI_SCREEN_DISABLE$DO_XINDI_LIMIT$DO_OBICO_LIMIT$DO_OBICO_STREAMING$DO_WIFI_DISABLE" = "00000000" ]; then
        echo "Nothing selected."
        return 1
    fi
}

show_apply_plan() {
    echo
    echo "===== APPLY PLAN ====="

    if [ "$DO_OLD_TUNING_DISABLE" = "1" ]; then
        old_tuning_disabled && echo "- Old community tuning boot script: already done" || echo "- Old community tuning boot script: will disable"
    fi

    if [ "$DO_CPU_PERFORMANCE" = "1" ]; then
        cpu_performance_applied && echo "- CPU governor performance service: already done" || echo "- CPU governor performance service: will apply"
    fi

    if [ "$DO_SERVICE_WEIGHTS" = "1" ]; then
        if core_weights_applied && ! strict_affinity_applied; then
            echo "- Core service CPU weights-only mode: already done"
        else
            echo "- Core service CPU weights-only mode: will apply/update"
        fi
    fi

    if [ "$DO_STRICT_AFFINITY" = "1" ]; then
        if strict_affinity_applied && core_weights_applied; then
            echo "- Strict CPU affinity mode: already done"
        else
            echo "- Strict CPU affinity mode: will apply/update"
            echo "  - Klipper CPU 1/2"
            echo "  - Moonraker/nginx/webcamd CPU 3"
            echo "  - Includes core CPU weights"
        fi
    fi

    if [ "$DO_QIDI_SCREEN_DISABLE" = "1" ]; then
        qidi_screen_disabled && echo "- QIDI screen service / xindi: already disabled and masked" || echo "- QIDI screen service / xindi: will disable and mask"
    fi

    if [ "$DO_XINDI_LIMIT" = "1" ]; then
        xindi_limit_applied && echo "- xindi/makerbase-client limit: already done" || echo "- xindi/makerbase-client limit: will apply/update"
    fi

    if [ "$DO_OBICO_LIMIT" = "1" ]; then
        obico_limit_applied && echo "- Obico CPU limit: already done" || echo "- Obico CPU limit: will apply/update"
    fi

    if [ "$DO_OBICO_STREAMING" = "1" ]; then
        if obico_streaming_disabled && obico_logging_info; then
            echo "- Obico streaming disabled + logging INFO: already done"
        else
            echo "- Obico streaming disabled + logging INFO: will apply/update"
        fi
    fi

    if [ "$DO_WIFI_DISABLE" = "1" ]; then
        wifi_disable_applied && echo "- Wi-Fi disable: already done" || echo "- Wi-Fi disable: will apply if safe"
    fi

    echo "- Backup current files before changes"
    echo "- Restart only changed/touched services"
    echo
}

show_undo_plan() {
    echo
    echo "===== UNDO PLAN ====="
    [ "$DO_OLD_TUNING_DISABLE" = "1" ] && echo "- Re-enable old community tuning boot script"
    [ "$DO_CPU_PERFORMANCE" = "1" ] && echo "- Remove CPU performance governor service from this script"
    [ "$DO_SERVICE_WEIGHTS" = "1" ] && echo "- Remove core service weights and strict affinity overrides"
    [ "$DO_QIDI_SCREEN_DISABLE" = "1" ] && echo "- Re-enable QIDI screen service / xindi"
    [ "$DO_XINDI_LIMIT" = "1" ] && echo "- Remove xindi/makerbase-client systemd limit"
    [ "$DO_OBICO_LIMIT" = "1" ] && echo "- Remove Obico CPU limit"
    [ "$DO_OBICO_STREAMING" = "1" ] && echo "- Set Obico disable_video_streaming=False"
    [ "$DO_WIFI_DISABLE" = "1" ] && echo "- Re-enable makerbase-wlan0.service and wlan0"
    echo "- Backup current files before undo"
    echo "- Restart only changed/touched services"
    echo
}

do_apply_menu() {
    clear
    select_apply_options || return 0
    show_apply_plan

    if ! ask_yes_no "Commit/apply these selected changes now?" "n"; then
        echo "Aborted. No changes applied."
        read -r -p "Press Enter to continue..." _
        return 0
    fi

    mkdir -p "$BACKUP_ROOT"
    backup_current_state

    [ "$DO_OLD_TUNING_DISABLE" = "1" ] && apply_disable_old_tuning
    [ "$DO_CPU_PERFORMANCE" = "1" ] && install_cpu_performance_service

    if [ "$DO_SERVICE_WEIGHTS" = "1" ] || [ "$DO_STRICT_AFFINITY" = "1" ]; then
        install_core_service_weights
    fi

    [ "$DO_QIDI_SCREEN_DISABLE" = "1" ] && disable_qidi_screen_service
    [ "$DO_XINDI_LIMIT" = "1" ] && install_xindi_limit
    [ "$DO_OBICO_LIMIT" = "1" ] && install_obico_limit
    [ "$DO_OBICO_STREAMING" = "1" ] && patch_obico_streaming_disabled
    [ "$DO_WIFI_DISABLE" = "1" ] && disable_wifi_if_safe

    restart_changed_services

    echo
    echo "Applied selected Plus4 optional tuning changes."
    read -r -p "Press Enter to continue..." _
}

do_undo_menu() {
    clear
    select_undo_options || return 0
    show_undo_plan

    if ! ask_yes_no "Commit/undo these selected changes now?" "n"; then
        echo "Aborted. No changes undone."
        read -r -p "Press Enter to continue..." _
        return 0
    fi

    mkdir -p "$BACKUP_ROOT"
    backup_current_state

    [ "$DO_OLD_TUNING_DISABLE" = "1" ] && undo_disable_old_tuning
    [ "$DO_CPU_PERFORMANCE" = "1" ] && undo_cpu_performance
    [ "$DO_SERVICE_WEIGHTS" = "1" ] && undo_core_service_weights
    [ "$DO_QIDI_SCREEN_DISABLE" = "1" ] && enable_qidi_screen_service
    [ "$DO_XINDI_LIMIT" = "1" ] && undo_xindi_limit
    [ "$DO_OBICO_LIMIT" = "1" ] && undo_obico_limit
    [ "$DO_OBICO_STREAMING" = "1" ] && patch_obico_streaming_enabled
    [ "$DO_WIFI_DISABLE" = "1" ] && undo_wifi_disable

    restart_changed_services

    echo
    echo "Undone selected Plus4 optional tuning changes."
    read -r -p "Press Enter to continue..." _
}

print_matching_services() {
    local pattern="klippy|xindi|makerbase|moonraker|obico|janus|mjpg|webcam|nginx|tailscale|udp_server|ffmpeg|aic|wlan"

    ps -eo pid,ppid,ni,psr,stat,%cpu,%mem,comm,args --sort=-%cpu \
        | awk -v pat="$pattern" 'NR == 1 || ($0 ~ pat && $0 !~ /awk -v pat/)'
}

plain_status_summary() {
    echo "===== EASY STATUS ====="

    old_tuning_disabled \
        && echo "Old community tuning boot script: disabled or not installed" \
        || echo "Old community tuning boot script: ENABLED"

    cpu_performance_applied \
        && echo "CPU performance service from this script: applied" \
        || echo "CPU performance service from this script: not applied"

    all_governors_performance \
        && echo "CPU governor right now: performance" \
        || echo "CPU governor right now: not fully performance"

    if core_weights_applied && ! strict_affinity_applied; then
        echo "Scheduling mode: core weights only"
    elif core_weights_applied && strict_affinity_applied; then
        echo "Scheduling mode: strict CPU affinity"
    else
        echo "Scheduling mode: not applied"
    fi

    qidi_screen_disabled \
        && echo "QIDI screen service / xindi: disabled and masked" \
        || echo "QIDI screen service / xindi: enabled or not fully disabled"

    qidi_screen_processes_running \
        && echo "QIDI screen/QIDILink processes: running" \
        || echo "QIDI screen/QIDILink processes: not running"

    xindi_limit_applied \
        && echo "xindi systemd limit on CPU 0: applied" \
        || echo "xindi systemd limit on CPU 0: not applied"

    obico_limit_applied \
        && echo "Obico CPU limit: applied" \
        || echo "Obico CPU limit: not applied"

    obico_streaming_disabled \
        && echo "Obico live video streaming: disabled" \
        || echo "Obico live video streaming: enabled or not configured"

    obico_logging_info \
        && echo "Obico logging level INFO: applied" \
        || echo "Obico logging level INFO: not applied"

    wifi_disable_applied \
        && echo "Wi-Fi service/interface: disabled" \
        || echo "Wi-Fi service/interface: not fully disabled"

    echo
}

status_report() {
    clear

    echo "===== TIME / UPTIME / LOAD ====="
    date
    uptime
    echo

    echo "===== MEMORY ====="
    free -h
    echo

    plain_status_summary

    echo "===== NETWORK ====="
    ip -br addr
    echo

    echo "===== TOP PRINT / NETWORK SERVICES ====="
    print_matching_services
    echo

    echo "===== OBICO CONFIG ====="
    grep -nEi "disable_video_streaming|snapshot_url|stream_url|level" /home/mks/printer_data/config/moonraker-obico.cfg 2>/dev/null || true
    echo

    read -r -p "Press Enter to continue..." _
}

main_menu() {
    require_root

    while true; do
        clear
        echo "QiDi Plus4 Optional Tuning"
        echo
        echo "Choose a section:"
        echo
        echo "1. Apply optimizations"
        echo "2. Undo optimizations"
        echo "3. View status"
        echo "4. Exit"
        echo

        read -r -p "Selection [1-4]: " choice

        case "$choice" in
            1) do_apply_menu ;;
            2) do_undo_menu ;;
            3) status_report ;;
            4|q|Q) clear; exit 0 ;;
            *) echo "Invalid selection."; sleep 1 ;;
        esac
    done
}

main_menu
