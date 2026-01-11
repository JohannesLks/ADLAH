#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ADLAH - Adaptive Deep Learning Anomaly Detection Honeynet <https://github.com/JohannesLks/ADLAH/>
# Copyright (C) 2025  Lukas Johannes Möller
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
set -euo pipefail

CONFIG_FILE="/etc/madcat/config.lua"
RUN_SCRIPT="/opt/madcat/scripts/run_madcat.sh"
LOG_DIR="/data"
STARTUP_LOG="/var/log/madcat/startup.log"
PATCH_FILE="/opt/madcat/bin/madcat_config.patch"
ENRICHED_LOG="$LOG_DIR/enriched.json.log"
touch "$ENRICHED_LOG"
chmod 644 "$ENRICHED_LOG"
chown -R madcat:madcat "$LOG_DIR"
mkdir -p "$(dirname "$STARTUP_LOG")"
exec > >(tee -a "$STARTUP_LOG") 2>&1

echo "[STARTUP] Initializing MADCAT container..."

if [[ -f "$PATCH_FILE" ]]; then
  echo "Applying patch: $PATCH_FILE"
  patch --batch --forward -p1 < "$PATCH_FILE" || \
      echo " Context does not match or already patched, skipping."
else
  echo "No patch file found at $PATCH_FILE, skipping."
fi

mkdir -p /var/log/audit
touch /var/log/audit/audit.log
chown root:root /var/log/audit/audit.log

echo "⇒ Starting auditd..."
auditd start || echo " auditd failed to start, continuing anyway."
sleep 1

if [[ -n "${HIVE_IP:-}" ]]; then
  echo "Setting HIVE_IP in config.lua to: $HIVE_IP"
  sed -i "s|<HIVE_SERVER_IP>|$HIVE_IP|g" "$CONFIG_FILE"
else
  echo "  HIVE_IP not set, using placeholder in config.lua"
fi

echo "Creating log directories & files..."
mkdir -p "$LOG_DIR" /tmp /var/log/madcat
touch "$LOG_DIR"/{madcat.log,monitoring.log,\
error.enrichment.log,error.udp.log,error.icmp.log,\
error.raw.log,error.tcp.log,error.tcppost.log}
chmod -R 755 "$LOG_DIR"

find /opt/madcat/scripts -type f -exec sed -i 's/\bsudo\b //g' {} + || true

if [[ -n "${MADCAT_INTERFACE:-}" ]]; then
  MADCAT_IF="$MADCAT_INTERFACE"
  MADCAT_IP="${MADCAT_IP:-$(ip -4 addr show "$MADCAT_IF" \
               | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)}"
  echo "MADCAT_INTERFACE set by ENV: '$MADCAT_IF' ($MADCAT_IP)"
else
  echo "Available interfaces:"
  ip -o link show | awk -F': ' '{print $2}' | grep -vE 'lo|docker|br|vir|veth'

  DEFAULT_IF=${MGMT_INTERFACE:-$(ip route | awk '/default/ {print $5}' | head -n1)}
  MADCAT_IF=$(ip -o link show | awk -F': ' '{print $2}' \
             | grep -vE "lo|docker|br|vir|veth|${DEFAULT_IF}" | head -n1)

  if [[ -z "$MADCAT_IF" ]]; then
    echo " No alternative interface found. Aborting."
    exit 1
  fi

  MADCAT_IP=$(ip -4 addr show "$MADCAT_IF" \
              | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
  if [[ -z "$MADCAT_IP" ]]; then
    echo " Could not determine IP. Aborting."
    exit 1
  fi
  echo "Using interface '$MADCAT_IF' with IP '$MADCAT_IP'"
fi

sed -i "s|<REPLACE_IFACE>|$MADCAT_IF|g" "$CONFIG_FILE"
sed -i "s|<REPLACE_IP>|$MADCAT_IP|g"    "$CONFIG_FILE"
sed -i "s|wlp8s0|$MADCAT_IF|g; s|enp9s0|$MADCAT_IF|g" \
       "/etc/madcat/monitoring_config.py"

echo "Enabling IP forwarding in kernel"
sysctl -w net.ipv4.ip_forward=1 || echo "  Could not set net.ipv4.ip_forward"

sed -i -E \
  -e "s/(iptables .* -i )[^ ]+/\1${MADCAT_IF}/g" \
  -e "s/(--to(=destination)? )[^ ]+/\1${MADCAT_IP}:65535/g" \
  "$RUN_SCRIPT"

echo "Checking MADCAT components..."
missing=0
for f in /opt/madcat/{udp_ip_port_mon,icmp_mon,raw_mon,tcp_ip_port_mon,\
enrichment_processor.py,tcp_ip_port_mon_postprocessor.py}; do
  [[ -f "$f" ]] || { echo " Missing: $f"; missing=1; }
done
(( missing == 0 )) || { echo " Aborting."; exit 1; }

rm -f /tmp/logs.erm /tmp/connect_json.tpm /tmp/header_json.tpm
mkfifo /tmp/logs.erm /tmp/connect_json.tpm /tmp/header_json.tpm

chmod +x "$RUN_SCRIPT"
ln -sf /opt/madcat/bin/enrichment_processor.py /opt/madcat/enrichment_processor.py

echo " Starting MADCAT..."
(bash "$RUN_SCRIPT" >> "$LOG_DIR/madcat.log" 2>> "$LOG_DIR/error.tcp.log") &
MADCAT_PID=$!
sleep 3

echo "Starting monitoring..."
/usr/bin/python3 /opt/madcat/bin/monitoring/monitoring.py \
  /etc/madcat/monitoring_config.py \
  >> "$LOG_DIR/monitoring.log" 2>> "$LOG_DIR/error.monitoring.log" &

REDIRECTOR_SCRIPT="/opt/madcat/redirector.py"
if [[ -f "$REDIRECTOR_SCRIPT" ]]; then
  echo "Starting RL-DNAT Redirector..."
  export HIVE_IP="$HIVE_IP"
  export MADCAT_INTERFACE_IP="$MADCAT_IP"
  /usr/bin/env python3 "$REDIRECTOR_SCRIPT" &
else
  echo " No redirector found at $REDIRECTOR_SCRIPT"
fi

wait