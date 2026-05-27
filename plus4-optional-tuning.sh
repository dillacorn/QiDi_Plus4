#!/usr/bin/env bash
set -euo pipefail

# plus4-optional-tuning.sh
# Interactive QiDi Plus4 optional host-load tuning for reducing Timer Too Close / MCU timeout risk.
#
# Usage:
#   chmod +x /home/mks/plus4-optional-tuning.sh
#   /home/mks/plus4-optional-tuning.sh apply
#   /home/mks/plus4-optional-tuning.sh check
#   /home/mks/plus4-optional-tuning.sh revert

ACTION="${1:-check}"

BACKUP_ROOT="/root/plus4-optional-tuning-backups"
STAMP="$(date +%Y%m%d-%H%M%S)"

DO_CPU_PERFORMANCE=0
DO_SERVICE_WEIGHTS=0
DO_XINDI_LIMIT=0
DO_OBICO_LIMIT=0
DO_OBICO_STREAMING=0
DO_WIFI_DISABLE=0

XINDI_CPU_QUOTA="25%"
OBICO_CPU_QUOTA="50%"

declare -a MENU_LABELS=()
declare -a MENU_SELECTED=()

require_root() {
    if [ "${EUID}" -ne 0 ]; then
        exec sudo bash "$0" "$@"
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
    backup_path "/etc/systemd/system/makerbase-client.service.d/override.conf" "$backup_dir"
    backup_path "/etc/systemd/system/moonraker-obico.service.d/override.conf" "$backup_dir"
    backup_path "/etc/systemd/system/plus4-cpu-performance.service" "$backup_dir"
    backup_path "/usr/local/sbin/plus4-cpu-performance" "$backup_dir"
    backup_path "/home/mks/printer_data/config/moonraker-obico.cfg" "$backup_dir"
    backup_path "/etc/default/cpufrequtils" "$backup_dir"

    echo "$backup_dir" > "$BACKUP_ROOT/latest"
    echo "Backup saved: $backup_dir"
}

install_cpu_performance_service() {
    cat > /usr/local/sbin/plus4-cpu-performance <<'EOF'
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

    cat > /etc/systemd/system/plus4-cpu-performance.service <<'EOF'
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
    mkdir -p \
        /etc/systemd/system/klipper.service.d \
        /etc/systemd/system/moonraker.service.d \
        /etc/systemd/system/webcamd.service.d \
        /etc/systemd/system/nginx.service.d

    cat > /etc/systemd/system/klipper.service.d/override.conf <<'EOF'
[Service]
CPUAccounting=true
CPUWeight=700
EOF

    cat > /etc/systemd/system/moonraker.service.d/override.conf <<'EOF'
[Service]
CPUAccounting=true
CPUWeight=80
EOF

    cat > /etc/systemd/system/webcamd.service.d/override.conf <<'EOF'
[Service]
Nice=2
CPUAccounting=true
CPUWeight=10
EOF

    cat > /etc/systemd/system/nginx.service.d/override.conf <<'EOF'
[Service]
Nice=1
CPUAccounting=true
CPUWeight=30
EOF

    systemctl daemon-reload
}

install_xindi_limit() {
    mkdir -p /etc/systemd/system/makerbase-client.service.d

    cat > /etc/systemd/system/makerbase-client.service.d/override.conf <<EOF
[Service]
Nice=5
CPUAccounting=true
CPUWeight=10
CPUQuota=${XINDI_CPU_QUOTA}
CPUAffinity=3
EOF

    systemctl daemon-reload
}

install_obico_limit() {
    if ! service_exists "moonraker-obico.service"; then
        echo "Skipping Obico limit: moonraker-obico.service not found."
        return 0
    fi

    mkdir -p /etc/systemd/system/moonraker-obico.service.d

    cat > /etc/systemd/system/moonraker-obico.service.d/override.conf <<EOF
[Service]
Nice=5
CPUAccounting=true
CPUWeight=30
CPUQuota=${OBICO_CPU_QUOTA}
EOF

    systemctl daemon-reload
}

patch_obico_streaming() {
    local cfg="/home/mks/printer_data/config/moonraker-obico.cfg"

    if [ ! -f "$cfg" ]; then
        echo "Skipping Obico streaming config: $cfg not found."
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
}

disable_wifi_if_safe() {
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
        echo "Skipping Wi-Fi disable: current SSH session appears to use wlan0."
        return 0
    fi

    if [ "$eth_has_ip" != "1" ]; then
        echo "Skipping Wi-Fi disable: eth0 has no IPv4 address."
        return 0
    fi

    if service_exists "makerbase-wlan0.service"; then
        systemctl disable makerbase-wlan0.service >/dev/null 2>&1 || true
        systemctl stop makerbase-wlan0.service >/dev/null 2>&1 || true
    fi

    ip link set wlan0 down 2>/dev/null || true
}

restart_touched_services() {
    local services=()

    if [ "$DO_SERVICE_WEIGHTS" = "1" ] && service_exists "klipper.service"; then
        services+=("klipper.service")
    fi

    if [ "$DO_SERVICE_WEIGHTS" = "1" ] && service_exists "moonraker.service"; then
        services+=("moonraker.service")
    fi

    if [ "$DO_SERVICE_WEIGHTS" = "1" ] && service_exists "webcamd.service"; then
        services+=("webcamd.service")
    fi

    if [ "$DO_SERVICE_WEIGHTS" = "1" ] && service_exists "nginx.service"; then
        services+=("nginx.service")
    fi

    if [ "$DO_XINDI_LIMIT" = "1" ] && service_exists "makerbase-client.service"; then
        services+=("makerbase-client.service")
    fi

    if { [ "$DO_OBICO_LIMIT" = "1" ] || [ "$DO_OBICO_STREAMING" = "1" ]; } && service_exists "moonraker-obico.service"; then
        services+=("moonraker-obico.service")
    fi

    if [ "${#services[@]}" -gt 0 ]; then
        systemctl restart "${services[@]}"
    fi
}

render_checkbox_menu() {
    local current="$1"
    local checked
    local prefix
    local marker
    local i

    clear
    echo "QiDi Plus4 Optional Tuning"
    echo
    echo "All changes start unchecked."
    echo "Use Up/Down or j/k to move."
    echo "Use Space or number keys to toggle."
    echo "Press Enter to continue."
    echo "Press q to quit."
    echo

    for i in "${!MENU_LABELS[@]}"; do
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
    if [ ! -t 0 ]; then
        echo "Interactive apply requires a terminal."
        exit 1
    fi

    MENU_LABELS=(
        "Force CPU governor to performance"
        "Apply core service CPU weights for Klipper, Moonraker, nginx, and webcamd"
        "Limit QIDI screen service / xindi with systemd"
        "Keep Obico running but lower priority and cap CPU usage"
        "Disable Obico live video streaming while keeping Obico running"
        "Disable Wi-Fi service/interface if Ethernet is active"
    )

    MENU_SELECTED=(0 0 0 0 0 0)

    local current=0
    local key=""
    local rest=""
    local max_index
    local idx

    max_index=$((${#MENU_LABELS[@]} - 1))

    while true; do
        render_checkbox_menu "$current"

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
                clear
                echo "Aborted. No changes applied."
                exit 0
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
            1|2|3|4|5|6)
                idx=$((key - 1))
                toggle_menu_item "$idx"
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

    DO_CPU_PERFORMANCE="${MENU_SELECTED[0]}"
    DO_SERVICE_WEIGHTS="${MENU_SELECTED[1]}"
    DO_XINDI_LIMIT="${MENU_SELECTED[2]}"
    DO_OBICO_LIMIT="${MENU_SELECTED[3]}"
    DO_OBICO_STREAMING="${MENU_SELECTED[4]}"
    DO_WIFI_DISABLE="${MENU_SELECTED[5]}"
}

interactive_apply() {
    require_root "$ACTION"

    checkbox_menu

    if [ "$DO_XINDI_LIMIT" = "1" ]; then
        XINDI_CPU_QUOTA="$(ask_value "xindi CPU quota" "$XINDI_CPU_QUOTA")"
    fi

    if [ "$DO_OBICO_LIMIT" = "1" ]; then
        OBICO_CPU_QUOTA="$(ask_value "Obico CPU quota" "$OBICO_CPU_QUOTA")"
    fi

    echo
    echo "===== PLAN ====="
    [ "$DO_CPU_PERFORMANCE" = "1" ] && echo "- Force CPU governor to performance"
    [ "$DO_SERVICE_WEIGHTS" = "1" ] && echo "- Apply core service CPU weights"
    [ "$DO_XINDI_LIMIT" = "1" ] && echo "- Limit xindi/makerbase-client: Nice=5 CPUWeight=10 CPUQuota=$XINDI_CPU_QUOTA CPUAffinity=3"
    [ "$DO_OBICO_LIMIT" = "1" ] && echo "- Limit Obico: Nice=5 CPUWeight=30 CPUQuota=$OBICO_CPU_QUOTA"
    [ "$DO_OBICO_STREAMING" = "1" ] && echo "- Set Obico disable_video_streaming=True and logging level INFO"
    [ "$DO_WIFI_DISABLE" = "1" ] && echo "- Disable makerbase-wlan0.service and bring wlan0 down if safe"
    echo "- Backup current files before changes"
    echo "- Restart only touched services"
    echo

    if [ "$DO_CPU_PERFORMANCE$DO_SERVICE_WEIGHTS$DO_XINDI_LIMIT$DO_OBICO_LIMIT$DO_OBICO_STREAMING$DO_WIFI_DISABLE" = "000000" ]; then
        echo "Nothing selected. Exiting."
        exit 0
    fi

    if ! ask_yes_no "Commit/apply these changes now?" "n"; then
        echo "Aborted. No changes applied."
        exit 0
    fi

    mkdir -p "$BACKUP_ROOT"
    backup_current_state

    [ "$DO_CPU_PERFORMANCE" = "1" ] && install_cpu_performance_service
    [ "$DO_SERVICE_WEIGHTS" = "1" ] && install_core_service_weights
    [ "$DO_XINDI_LIMIT" = "1" ] && install_xindi_limit
    [ "$DO_OBICO_LIMIT" = "1" ] && install_obico_limit
    [ "$DO_OBICO_STREAMING" = "1" ] && patch_obico_streaming
    [ "$DO_WIFI_DISABLE" = "1" ] && disable_wifi_if_safe

    restart_touched_services

    echo
    echo "Applied selected Plus4 optional tuning changes."
    echo
    check_state
}

revert_tuning() {
    require_root "$ACTION"

    echo
    echo "This removes all plus4-optional-tuning systemd overrides and re-enables makerbase-wlan0.service."
    echo "It does not automatically restore moonraker-obico.cfg. Backups are kept under $BACKUP_ROOT."
    echo

    if ! ask_yes_no "Commit/revert these changes now?" "n"; then
        echo "Aborted. No changes reverted."
        exit 0
    fi

    rm -f \
        /etc/systemd/system/klipper.service.d/override.conf \
        /etc/systemd/system/moonraker.service.d/override.conf \
        /etc/systemd/system/webcamd.service.d/override.conf \
        /etc/systemd/system/nginx.service.d/override.conf \
        /etc/systemd/system/makerbase-client.service.d/override.conf \
        /etc/systemd/system/moonraker-obico.service.d/override.conf \
        /etc/systemd/system/plus4-cpu-performance.service \
        /usr/local/sbin/plus4-cpu-performance

    rmdir \
        /etc/systemd/system/klipper.service.d \
        /etc/systemd/system/moonraker.service.d \
        /etc/systemd/system/webcamd.service.d \
        /etc/systemd/system/nginx.service.d \
        /etc/systemd/system/makerbase-client.service.d \
        /etc/systemd/system/moonraker-obico.service.d \
        2>/dev/null || true

    if service_exists "makerbase-wlan0.service"; then
        systemctl enable makerbase-wlan0.service >/dev/null 2>&1 || true
        systemctl start makerbase-wlan0.service >/dev/null 2>&1 || true
    fi

    systemctl daemon-reload

    local services=()

    service_exists "klipper.service" && services+=("klipper.service")
    service_exists "makerbase-client.service" && services+=("makerbase-client.service")
    service_exists "moonraker.service" && services+=("moonraker.service")
    service_exists "webcamd.service" && services+=("webcamd.service")
    service_exists "nginx.service" && services+=("nginx.service")
    service_exists "moonraker-obico.service" && services+=("moonraker-obico.service")

    if [ "${#services[@]}" -gt 0 ]; then
        systemctl restart "${services[@]}"
    fi

    echo
    echo "Removed Plus4 optional tuning overrides."
    echo
    echo "Latest backup:"

    if [ -f "$BACKUP_ROOT/latest" ]; then
        cat "$BACKUP_ROOT/latest"
    else
        echo "No backup marker found."
    fi

    echo
    check_state
}

print_matching_services() {
    local pattern="klippy|xindi|makerbase|moonraker|obico|janus|mjpg|webcam|nginx|tailscale|udp_server|ffmpeg|aic|wlan"

    ps -eo pid,ppid,ni,psr,stat,%cpu,%mem,comm,args --sort=-%cpu \
        | awk -v pat="$pattern" 'NR == 1 || ($0 ~ pat && $0 !~ /awk -v pat/)'
}

print_nice_check() {
    local pattern="mjpg|xindi|nginx|moonraker|obico|klippy|tailscale"

    ps axl \
        | awk -v pat="$pattern" '$0 ~ pat && $0 !~ /awk -v pat/ {print $3, $6, $13, $14, $15}'
}

check_state() {
    echo "===== TIME / UPTIME / LOAD ====="
    date
    uptime
    echo

    echo "===== MEMORY ====="
    free -h
    echo

    echo "===== CPU GOVERNOR ====="
    for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$f: $(cat "$f" 2>/dev/null)"
    done
    echo

    echo "===== NETWORK ====="
    ip -br addr
    echo

    echo "===== SYSTEMD LIMITS: KLIPPER ====="
    systemctl show klipper.service -p Nice -p CPUAccounting -p CPUWeight -p CPUQuotaPerSecUSec 2>/dev/null || true
    echo

    echo "===== SYSTEMD LIMITS: MOONRAKER ====="
    systemctl show moonraker.service -p Nice -p CPUAccounting -p CPUWeight -p CPUQuotaPerSecUSec 2>/dev/null || true
    echo

    echo "===== SYSTEMD LIMITS: XINDI / MAKERBASE ====="
    systemctl show makerbase-client.service -p Nice -p CPUAccounting -p CPUWeight -p CPUQuotaPerSecUSec -p AllowedCPUs 2>/dev/null || true
    echo

    echo "===== SYSTEMD LIMITS: OBICO ====="
    systemctl show moonraker-obico.service -p Nice -p CPUAccounting -p CPUWeight -p CPUQuotaPerSecUSec -p AllowedCPUs 2>/dev/null || true
    echo

    echo "===== OBICO CONFIG ====="
    grep -nEi "disable_video_streaming|snapshot_url|stream_url|level" /home/mks/printer_data/config/moonraker-obico.cfg 2>/dev/null || true
    echo

    echo "===== TOP PRINT / NETWORK SERVICES ====="
    print_matching_services
    echo

    echo "===== NICE CHECK ====="
    print_nice_check
    echo

    echo "===== SERVICE STATES ====="
    systemctl --no-pager --type=service \
        | awk '/klipper|moonraker|obico|makerbase|webcam|nginx|tailscale|mjpg|xindi|wlan/'
}

case "$ACTION" in
    apply)
        interactive_apply
        ;;
    check)
        check_state
        ;;
    revert)
        revert_tuning
        ;;
    *)
        echo "Usage: $0 {apply|check|revert}"
        exit 2
        ;;
esac