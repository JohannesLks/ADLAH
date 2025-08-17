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

# =====================================
# Configuration
# =====================================
HIVE_CERTBOT_CONF="$(pwd)/hive/nginx/certbot.conf"
HIVE_CERTBOT_WEBROOT="/var/www/certbot"

# =====================================
# Helper Functions
# =====================================
log() { echo -e "\e[32m[CERTBOT]\e[0m $*"; }
warn() { echo -e "\e[33m[CERTBOT] \e[0m $*"; }
error() { echo -e "\e[31m[CERTBOT] \e[0m $*" >&2; }

# =====================================
# Validation
# =====================================
check_certbot() {
    if ! [ -x "$(command -v certbot)" ]; then
        log "Certbot not found. Installing..."
        sudo apt-get update
        sudo apt-get install -y certbot
    else
        log "Certbot is already installed."
    fi
}

# =====================================
# Certificate Generation
# =====================================
request_certificate() {
    log "Requesting Let's Encrypt certificate..."
    sudo certbot certonly --webroot --webroot-path=/var/www/certbot \
        -d adlah.dev --agree-tos --no-eff-email --non-interactive --register-unsafely-without-email
}

copy_certificates() {
    log "Copying certificate to Nginx directory..."
    local cert_path="$(pwd)/hive/nginx/certs/cert.pem"
    local key_path="$(pwd)/hive/nginx/certs/key.pem"

    sudo mkdir -p "$(pwd)/hive/nginx/certs/"
    sudo cp "/etc/letsencrypt/live/adlah.dev/fullchain.pem" "$cert_path"
    if [ $? -ne 0 ]; then
        error "Failed to copy certificate."
        return 1
    fi

    sudo cp "/etc/letsencrypt/live/adlah.dev/privkey.pem" "$key_path"
    if [ $? -ne 0 ]; then
        error "Failed to copy private key."
        return 1
    fi

    sudo chmod 644 "$cert_path" "$key_path"
    log "Certificate and key copied successfully."
}

start_temp_nginx() {
    if docker ps --format '{{.Names}}' | grep -qx 'hive-nginx-1'; then
        log "Detected running hive-nginx-1 on port 80 – skipping temp container. Ensure webroot served."
        return 0
    fi
    log "Starting temporary Nginx container (no existing listener on :80)..."
    if docker ps -a --format '{{.Names}}' | grep -qx 'temp-nginx'; then
        log "Removing existing temp-nginx container..."
        docker rm -f temp-nginx >/dev/null 2>&1 || true
    fi
    docker run -d --name temp-nginx -p 80:80 \
        -v "$HIVE_CERTBOT_CONF:/etc/nginx/conf.d/default.conf" \
        -v "$HIVE_CERTBOT_WEBROOT:/var/www/certbot" \
        nginx
}

stop_temp_nginx() {
    if docker ps --format '{{.Names}}' | grep -qx 'temp-nginx'; then
        log "Stopping temporary Nginx container..."
        docker stop temp-nginx || true
        docker rm temp-nginx || true
    else
        log "No temp-nginx container to stop (production nginx reused)."
    fi
}

restart_nginx_manually() {
    log "Configuration and certificates are in place."
    log "Please run 'docker compose -f hive/docker-compose.yml restart nginx' to apply the changes."
}

test_ssl() {
    log "Testing SSL configuration..."
    sleep 5 # Wait for nginx to restart
    docker run --rm --network="host" appropriate/curl --fail --silent --show-error -k https://localhost > /dev/null
}

# =====================================
# Main Execution
# =====================================
validate_installation() {
    log "Validating certificate installation..."
    local cert_path="$(pwd)/hive/nginx/certs/cert.pem"
    
    if [ ! -f "$cert_path" ]; then
        error "Certificate file not found at $cert_path"
        return 1
    fi

    log "Certificate validation successful."
}
main() {
    log "Starting Certbot SSL certificate generation..."
    check_certbot
    start_temp_nginx
    
    if ! request_certificate; then
        error "Failed to request certificate. Aborting."
        stop_temp_nginx
        return 1
    fi
    
    stop_temp_nginx
    
    if ! copy_certificates; then
        error "Failed to copy certificates. Aborting."
        return 1
    fi
    
    restart_nginx_manually
    log "Certbot setup completed successfully."
}

# Run main function
main "$@"