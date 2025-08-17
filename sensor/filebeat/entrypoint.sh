#!/usr/bin/env bash
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

CERTDIR=/usr/share/filebeat/certs

while [ ! -f "$CERTDIR/logstash.crt" ] || [ ! -f "$CERTDIR/logstash.key" ]; do
  echo "→ warte auf Zertifikate in $CERTDIR…"
  sleep 2
done

exec /usr/local/bin/docker-entrypoint filebeat \
  -e \
  -strict.perms=false
