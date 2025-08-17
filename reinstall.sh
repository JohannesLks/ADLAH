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

# ADLAH Complete Reinstall Script
# Orchestrates the installation and deployment of ADLAH components

# =====================================
# Configuration
# =====================================
SENSOR_IP=10.1.0.5
SENSOR_USER=lukas
HIVE_IP=10.1.0.10
CLUSTER_IP=10.1.0.15
# Username used for Kibana / nginx basic auth (htpasswd). System user stays 'lukas'.
# Username for Kibana/nginx basic auth ONLY
KIBANA_AUTH_USER=adlah
# System user for SSH/cluster/sensor operations
SYSTEM_USER=lukas

# =====================================
# Helper Functions
# =====================================
log() { echo -e "\e[32m[REINSTALL]\e[0m $*"; }
warn() { echo -e "\e[33m[REINSTALL] \e[0m $*"; }
error() { echo -e "\e[31m[REINSTALL] \e[0m $*" >&2; }

# Check if password is provided
check_password() {
    if [[ -z "${PASS:-}" ]]; then
        read -rsp "Bitte Kibana-/Grafana-Passwort setzen: " PASS; echo
    fi
}

# Clean up previous installation
cleanup() {
    log "Cleaning up previous installation..."
    sudo rm -rf ~/hive 2>/dev/null || true
}

# =====================================
# Installation Steps
# =====================================

# Step 1: Install Hive
install_hive() {
    log "Step 1: Installing Hive..."
    export SENSOR_IP=$SENSOR_IP
    export SENSOR_USER=$SENSOR_USER
    export HIVE_IP=$HIVE_IP
    rm -rf ~/hive
    # Use dedicated Kibana/nginx basic auth user (not the system user)
    ~/ADLAH/install.sh --type hive --user "$KIBANA_AUTH_USER" \
        --yes --password "$PASS"
    
    log "Running Certbot setup..."
    ~/ADLAH/hive/scripts/certbot-setup.sh
}

# Step 2: Deploy Cluster
deploy_cluster() {
    log "Step 2: Deploying Cluster..."
    # The directory is created by deploy.sh, no need to create it here.
    sudo rm -rf $HOME/hive/cluster_kubeconfig/config_host
    # Cluster deployment must use system SSH user, not Kibana auth user
    ~/ADLAH/deploy.sh --cluster --ip $CLUSTER_IP \
        --user "$SYSTEM_USER" --grafana-pass "$PASS"
}

# Step 3: Setup Sensor
setup_sensor() {
    log "Step 3: Setting up Sensor..."
    ssh $SENSOR_USER@$SENSOR_IP "
        cd ~ && rm -rf ~/sensor && 
        cd ~/ADLAH && 
        git fetch --all && 
        git checkout dev && 
        git pull && 
    chmod +x ./install.sh && ./install.sh --type sensor --user "$SYSTEM_USER" \
            --hive-ip $HIVE_IP --madcat-if ens5 --mgmt-if ens4 \
            --yes --password \"$PASS\"
    "
}

# Step 4: Deploy Sensor
deploy_sensor() {
    log "Step 4: Deploying Sensor..."
    ~/ADLAH/deploy.sh --sensor --ip $SENSOR_IP \
        --user "$SYSTEM_USER"  # Sensor deploy uses system SSH user
}
# Step 4: Start Sensor Containers
start_sensor_containers() {
    log "Step 4: Starting Sensor containers..."
    ssh $SENSOR_USER@$SENSOR_IP "
        cd ~/sensor && 
        docker compose down && 
        docker compose build --no-cache && 
        docker compose up -d
    "
}

# Step 5: Start Hive Services
start_hive_services() {
    log "Step 5: Starting Hive services..."
    cd ~/hive
    docker compose down
    docker compose build --no-cache
    docker compose down
    docker compose up -d
}

# Step 6: Setup API Tunnel
setup_api_tunnel() {
    log "Step 6: Setting up API tunnel..."
    systemctl --user restart k8s-api-tunnel.service
    sleep 10
}

# Step 7: Test Connectivity
test_connectivity() {
    log "Step 7: Testing connectivity..."
    export KUBECONFIG=$HOME/hive/cluster_kubeconfig/config_host
    kubectl config use-context $(kubectl --kubeconfig "$KUBECONFIG" config get-contexts -o name | head -n 1) --kubeconfig "$KUBECONFIG"
    kubectl get nodes --insecure-skip-tls-verify
}


# =====================================
# Main Execution
# =====================================
main() {
    log " Starting ADLAH Complete Reinstall..."
    
    check_password
    cleanup

    # Generate fresh Kibana encryption keys (rotation) - 64 random hex chars each
    export XPACK_ENCRYPTED_SAVED_OBJECTS_KEY=$(openssl rand -hex 32)
    export XPACK_SECURITY_ENCRYPTIONKEY=$(openssl rand -hex 32)
    export XPACK_REPORTING_ENCRYPTIONKEY=$(openssl rand -hex 32)
    log "Generated new Kibana encryption keys (will invalidate prior sessions)."
    # Persist for docker compose (executed later inside ~/hive)
    mkdir -p "$HOME/hive" || true
    cat > "$HOME/hive/.env" <<EOF
XPACK_ENCRYPTED_SAVED_OBJECTS_KEY=${XPACK_ENCRYPTED_SAVED_OBJECTS_KEY}
XPACK_SECURITY_ENCRYPTIONKEY=${XPACK_SECURITY_ENCRYPTIONKEY}
XPACK_REPORTING_ENCRYPTIONKEY=${XPACK_REPORTING_ENCRYPTIONKEY}
EOF
    chmod 600 "$HOME/hive/.env"
    log "Wrote Kibana encryption keys to ~/hive/.env (chmod 600)."
    
    install_hive
    log "Ensuring port 6443 is free..."
    fuser -k 6443/tcp || true
    deploy_cluster
    setup_sensor
    deploy_sensor
    start_sensor_containers
    start_hive_services
    setup_api_tunnel
    test_connectivity
    
    log "🎉 ADLAH Reinstall completed!"
}

# Run main function
main "$@"