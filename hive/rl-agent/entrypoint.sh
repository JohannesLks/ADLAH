#!/bin/sh
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
set -e

HOST_KUBECONFIG="/app/kubeconfig_host"
CONTAINER_KUBECONFIG="/app/kubeconfig_container"

if [ -f "$HOST_KUBECONFIG" ]; then
    echo "Creating container-specific kubeconfig..."
    cp "$HOST_KUBECONFIG" "$CONTAINER_KUBECONFIG"
    sed -E -i 's|server: https://127\.0\.0\.1:([0-9]+)|server: https://host.docker.internal:\1|' "$CONTAINER_KUBECONFIG"
    echo "Kubeconfig modified for container access."
    export KUBECONFIG="$CONTAINER_KUBECONFIG"
elif [ -d "$HOST_KUBECONFIG" ]; then
    CANDIDATE_FILE=""
    for fname in config kubeconfig; do
        if [ -f "$HOST_KUBECONFIG/$fname" ]; then
            CANDIDATE_FILE="$HOST_KUBECONFIG/$fname"
            break
        fi
    done
    if [ -n "$CANDIDATE_FILE" ]; then
        echo "Creating container-specific kubeconfig from $CANDIDATE_FILE..."
        cp "$CANDIDATE_FILE" "$CONTAINER_KUBECONFIG"
        sed -E -i 's|server: https://127\.0\.0\.1:([0-9]+)|server: https://host.docker.internal:\1|' "$CONTAINER_KUBECONFIG"
        echo "Kubeconfig modified for container access."
        export KUBECONFIG="$CONTAINER_KUBECONFIG"
    else
        echo "WARNING: Host kubeconfig directory is empty at $HOST_KUBECONFIG. Continuing without Kubernetes access."
    fi
else
    echo "WARNING: Host kubeconfig not found at $HOST_KUBECONFIG. Continuing without Kubernetes access."
fi

echo "Waiting for Elasticsearch to become available..."
while ! curl -s -f "http://elasticsearch:9200/_cluster/health?wait_for_status=yellow&timeout=5s" > /dev/null; do
    echo "Elasticsearch is not available yet, sleeping..."
    sleep 5
done
echo "Elasticsearch is up!"

echo "Starting RL Agent application..."
exec python3 -u -m rl_agent.main "$@" 