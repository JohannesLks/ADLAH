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

# ── Exit-Codes ───────────────────────────────────────────────────────────────
EXIT_SUCCESS=0
EXIT_INVALID_PARAMS=1
EXIT_MISSING_DEPS=2
EXIT_PERMISSION_DENIED=3
EXIT_RSYNC_FAILED=4
EXIT_DOCKER_FAILED=5
EXIT_SYSTEM_SERVICE_FAILED=6
EXIT_QUIT=8

# ── Global Variables ─────────────────────────────────────────────────────────
USER_NAME=$(whoami)
REQUIREMENTS_FILE="./requirements.txt"
ENV_FILE="$HOME/.adlah_env"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"
SSH_PORT=22
KIBANA_ENCRYPTION_KEY=$(openssl rand -base64 32)

# ── Helper Functions ──────────────────────────────────────────────────────────
check_command() { command -v "$1" >/dev/null 2>&1; }

# Added colors and notes
C0='\e[0m'; C1='\e[36m'; C2='\e[32m'; C3='\e[33m'; C4='\e[31m'
info() { echo -e "${C2}[install]${C0} $*"; }
note() { echo -e "${C1}[install]${C0} $*"; }
warn() { echo -e "${C3}[install] $*${C0}"; }
die()  { echo -e "${C4}[install] $*${C0}" >&2; exit 1; }

# Robust subprocess execution with exit code handling
run_or_die() {
    local cmd="$*"
    local exit_code
    info "Executing: $cmd"
    eval "$cmd"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        die "Command failed (Exit code: $exit_code): $cmd"
    fi
    return $exit_code
}

# Safe subprocess execution with warning on error
run_or_warn() {
    local cmd="$*"
    local exit_code
    info "Executing: $cmd"
    eval "$cmd"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        warn "Command failed (Exit code: $exit_code): $cmd"
    fi
    return $exit_code
}

# Check if directory/file exists
check_path_exists() {
    local path="$1"
    local description="${2:-$path}"
    if [[ ! -e "$path" ]]; then
        die "Required path not found: $description ($path)"
    fi
}

# Check if directory exists and is not empty
check_dir_not_empty() {
    local dir="$1"
    local description="${2:-$dir}"
    check_path_exists "$dir" "$description"
    if [[ ! -d "$dir" ]]; then
        die "Path is not a directory: $description ($dir)"
    fi
    if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
        die "Directory is empty: $description ($dir)"
    fi
}

abort_if_fail() { 
    local cmd="$*"
    local exit_code
    eval "$cmd"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        die "Critical error at: $cmd (Exit code: $exit_code)"
    fi
    return $exit_code
}

# List all physical/virtual NICs except loopback & container bridges
list_nics() { 
    local nics
    nics=$(ip -o link show | awk -F': ' '{print $2}' | grep -vE 'lo|docker|br|vir|veth')
    if [[ -z "$nics" ]]; then
        die "No network interfaces found"
    fi
    echo "$nics"
}

# ── Validation Function ─────────────────────────────────────────────────────
validate_installation_parameters() {
  local errors=()
  local warnings=()

  info "🔍 Validating installation parameters..."

  # Check installation type
  if [[ -z "$INSTALL_TYPE" ]]; then
    errors+=("Installation type is not set (hive or sensor)")
  elif [[ "$INSTALL_TYPE" != "hive" && "$INSTALL_TYPE" != "sensor" ]]; then
    errors+=("Invalid installation type: '$INSTALL_TYPE' (must be 'hive' or 'sensor')")
  fi

  # Hive-specific validation
  if [[ "$INSTALL_TYPE" == "hive" ]]; then
    if [[ -z "$KIBANA_USER" ]]; then
      errors+=("Kibana username is required for Hive installation")
    elif [[ ! "$KIBANA_USER" =~ ^[a-zA-Z0-9_-]+$ ]]; then
      errors+=("Kibana username contains invalid characters (only a-z, A-Z, 0-9, _, - allowed)")
    fi

    if [[ -z "$KIBANA_PASSWORD" ]]; then
      errors+=("Kibana password is required for Hive installation")
    elif [[ ${#KIBANA_PASSWORD} -lt 8 ]]; then
      warnings+=("Kibana password is very short (less than 8 characters)")
    fi
  fi

  # Sensor-specific validation
  if [[ "$INSTALL_TYPE" == "sensor" ]]; then
    if [[ -z "$HIVE_IP" ]]; then
      errors+=("Hive IP is required for Sensor installation")
    elif ! [[ "$HIVE_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      errors+=("Invalid Hive IP address: '$HIVE_IP'")
    fi

    if [[ -z "$MADCAT_IF" ]]; then
      errors+=("MADCAT interface is required for Sensor installation")
    else
      # Check if interface exists
      if ! list_nics | grep -qx "$MADCAT_IF"; then
        errors+=("MADCAT interface '$MADCAT_IF' does not exist")
      fi
    fi

    # Optional: Validate management interface
    if [[ -n "$MGMT_IF" ]]; then
      if ! list_nics | grep -qx "$MGMT_IF"; then
        warnings+=("Management interface '$MGMT_IF' does not exist and will be ignored")
      fi
    fi
  fi

  # Check system requirements
  if ! check_command docker; then
    warnings+=("Docker is not installed - will be installed automatically")
  fi

  if ! check_command docker-compose && ! docker compose version >/dev/null 2>&1; then
    warnings+=("Docker Compose is not available - will be installed automatically")
  fi

  # Check SSH key
  if [[ ! -f "$SSH_KEY_PATH" ]]; then
    warnings+=("SSH key not found - will be generated automatically")
  fi

  # Check permissions
  if [[ $EUID -eq 0 ]]; then
    errors+=("Script should not be run as root")
  fi

  # Check directory permissions
  if [[ ! -w "$HOME" ]]; then
    errors+=("No write permission in home directory")
  fi

  # Show warnings
  if [[ ${#warnings[@]} -gt 0 ]]; then
    echo
    for warning in "${warnings[@]}"; do
      warn "WARNING: $warning"
    done
  fi

  # Show errors and exit on failure
  if [[ ${#errors[@]} -gt 0 ]]; then
    echo
    die "Validierungsfehler gefunden:${errors[*]/#/$'\n  - '}"
  fi

  info "Alle Parameter sind korrekt gesetzt"
  echo
}

run_compose_stack() {
  local dir="$1"
  echo "Starting Docker Compose in: $dir"
  cd "$dir" || die "Could not change to directory: $dir"
  
  # Prüfe ob docker-compose.yml existiert
  check_path_exists "docker-compose.yml" "Docker Compose Configuration"
  
  # Remove potential old containers to avoid type conflicts with bind mounts (file vs dir)
  run_or_warn docker compose down -v --remove-orphans
  
  # Start stack with error handling
  if ! docker compose up -d --force-recreate 2>&1 | tee /tmp/docker_compose.log; then
    echo "Docker Compose failed:"
    cat /tmp/docker_compose.log
    die "Failed to start Docker Compose stack"
  fi
  
  # Check if containers are running
  if ! docker compose ps | grep -q "Up"; then
    die "Docker Compose containers are not running correctly"
  fi
  
  docker compose ps
}

# ---------------------------------------------------------------------------
# New robust helpers
# ---------------------------------------------------------------------------
ensure_dir() {
  # Creates directory recursively (with sudo if needed) and sets ownership to the
  # current user, so subsequent write operations work without sudo.
  local path="$1"
  run_or_die sudo mkdir -p "$path"
  run_or_die sudo chown "$USER":"$USER" "$path"
}

cleanup_maybe_dir() {
  # Deletes an existing file or directory of the same name (sudo),
  # if it exists. Prevents "Is a directory" errors.
  local target="$1"
  if [ -e "$target" ]; then
    run_or_warn sudo rm -rf "$target"
  fi
}


# ────────────────────────────────────────────────────────────────────────────

# ── Parameter Parsing & Mode Selection ─────────────────────────────────────
usage() {
  cat <<EOF
ADLAH Installation Script

Usage: $0 --type <hive|sensor> [OPTIONS]

Required for --type=hive:
  --user <name>          Kibana username.
  --password <pass>      Kibana password. Can also be passed via \$PASS.

Required for --type=sensor:
  --hive-ip <ip>         IP address of the Hive server.
  --madcat-if <iface>    Network interface for MADCAT to listen on.

Optional:
  --mgmt-if <iface>      (Sensor only) Management interface for SSH/IAP.
  -y, --yes              Automatic yes to prompts; assumes automation.
  -h, --help             Show this help message.

Examples:
  $0 --type hive --user admin --password mypass
  $0 --type sensor --hive-ip 192.168.1.100 --madcat-if eth0
  $0 --type hive  # Interactive mode for missing parameters

Exit Codes:
  $EXIT_SUCCESS - Success
  $EXIT_INVALID_PARAMS - Invalid parameters
  $EXIT_MISSING_DEPS - Missing dependencies
  $EXIT_PERMISSION_DENIED - Permission denied
  $EXIT_RSYNC_FAILED - Copy failed
  $EXIT_DOCKER_FAILED - Docker error
  $EXIT_SYSTEM_SERVICE_FAILED - System service error
  $EXIT_QUIT - User aborted
EOF
  exit 0
}

# Default values
INSTALL_TYPE=""
KIBANA_USER=""
KIBANA_PASSWORD=""
HIVE_IP=""
MADCAT_IF=""
MGMT_IF=""
AUTO_CONFIRM="no"

# Parse arguments
if [[ $# -gt 0 ]]; then
  # Temp argument for password to avoid errors with empty $PASS
  CLI_PASSWORD="CLI_PASSWORD_NOT_SET"

  # Parse arguments
  eval set -- "$(getopt -o 'yh' --longoptions 'type:,user:,password:,hive-ip:,madcat-if:,mgmt-if:,yes,help' -n "$0" -- "$@")"

  while true; do
    case "$1" in
      --type) INSTALL_TYPE=$(echo "$2" | tr '[:upper:]' '[:lower:]'); shift 2;;
      --user) KIBANA_USER="$2"; shift 2;;
      --password) CLI_PASSWORD="$2"; shift 2;;
      --hive-ip) HIVE_IP="$2"; shift 2;;
      --madcat-if) MADCAT_IF="$2"; shift 2;;
      --mgmt-if) MGMT_IF="$2"; shift 2;;
      -y|--yes) AUTO_CONFIRM="yes"; shift;;
      -h|--help) usage; shift;;
      --) shift; break;;
      *) die "Internal error during parsing!";;
    esac
  done

  # Adopt password from CLI or $PASS variable
  if [[ "$CLI_PASSWORD" != "CLI_PASSWORD_NOT_SET" ]]; then
    KIBANA_PASSWORD="$CLI_PASSWORD"
  elif [[ -n "${PASS:-}" ]]; then
    KIBANA_PASSWORD="$PASS"
  fi
else
  # No arguments - show short help and ask interactively
  echo "ADLAH Installation Script"
  echo "Use: $0 --help for full options"
  echo "Or start without parameters for interactive mode"
  echo
fi

# Interactive query for missing parameters
if [[ -z "$INSTALL_TYPE" ]]; then
  echo -e "\nWelcome to ADLAH"
  echo "[H] Hive – ELK + RL-Agent"
  echo "[S] Sensor – MADCAT + Logweiterleitung"
  echo "[Q] Quit"

  while true; do
    read -rp "Selection (h/s/q): " choice
    case "${choice,,}" in
      h) INSTALL_TYPE="hive"; break;;
      s) INSTALL_TYPE="sensor"; break;;
      q) echo "Aborted."; exit $EXIT_QUIT;;
      *) warn "Invalid. Please h, s or q.";;
    esac
  done
fi

# Hive-specific interactive queries
if [[ "$INSTALL_TYPE" == "hive" ]]; then
  if [[ -z "$KIBANA_USER" ]]; then
    read -rp "Kibana username: " KIBANA_USER
  fi
  if [[ -z "$KIBANA_PASSWORD" ]]; then
    read -rsp "Kibana password: " KIBANA_PASSWORD; echo
  fi
fi

# Sensor-specific interactive queries
if [[ "$INSTALL_TYPE" == "sensor" ]]; then
  if [[ -z "$HIVE_IP" ]]; then
    read -rp "Hive IP (e.g. 10.1.0.10): " HIVE_IP
  fi
  if [[ -z "$MADCAT_IF" ]]; then
    echo
    echo "Available interfaces:"
    list_nics
    while true; do
      read -rp "Interface for MADCAT (Packet Capture/DNAT): " MADCAT_IF
      list_nics | grep -qx "$MADCAT_IF" && break
      warn "Invalid interface."
    done
  fi
  if [[ -z "$MGMT_IF" ]]; then
    read -rp "Interface for Management (IAP/SSH) [Enter = Auto]: " MGMT_IF
  fi
fi

# ── Parameter Validation ───────────────────────────────────────────────────
# Validate all parameters BEFORE installation starts
validate_installation_parameters


# ── System Preparation ──────────────────────────────────────────────────────
info "Initializing sudo session..."
run_or_die sudo -v

info "Checking Docker..."
if ! check_command docker; then
  info "Installing Docker..."
  run_or_die curl -fsSL https://get.docker.com | sudo sh
else
  info "Docker present."
fi

if ! id -nG "$USER_NAME" | grep -qw docker; then
  info "Adding $USER_NAME to docker group..."
  run_or_die sudo usermod -aG docker "$USER_NAME"
  warn "Please log in again or: sudo reboot"
  exit $EXIT_PERMISSION_DENIED
fi

info "Checking Docker Compose plugin..."
if ! docker compose version >/dev/null 2>&1; then
  run_or_die sudo apt update
  run_or_die sudo apt install -y docker-compose-plugin
fi

if [ -f "$REQUIREMENTS_FILE" ]; then
  info "Installing Python dependencies..."
  run_or_die pip3 install --upgrade pip
  run_or_die pip3 install -r "$REQUIREMENTS_FILE"
fi

if [ ! -f "$SSH_KEY_PATH" ]; then
  info "Generating new SSH key..."
  run_or_die ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
fi

info "Setting SSH port ($SSH_PORT)..."
SSH_DROPIN="/etc/ssh/sshd_config.d/20-adlah-port.conf"
# Write port to drop-in, not to the main file, to avoid corruption
CURRENT_PORT_LINE=$(sudo bash -lc "test -f '$SSH_DROPIN' && grep -E '^Port[[:space:]]+' '$SSH_DROPIN' | head -n1 || true")
if [[ "$CURRENT_PORT_LINE" != "Port $SSH_PORT" ]]; then
  run_or_die sudo mkdir -p /etc/ssh/sshd_config.d
  # Safely write via sudo tee; only printf output is piped
  run_or_die bash -lc "printf '%s\\n' 'Port $SSH_PORT' | sudo tee '$SSH_DROPIN' >/dev/null"
  # Validate configuration, then restart service
  abort_if_fail sudo sshd -t
  run_or_die sudo systemctl restart ssh || sudo systemctl restart sshd
else
  note "SSH port already configured."
fi

# ── HIVE Installation ────────────────────────────────────────────────────────
if [[ $INSTALL_TYPE == "hive" ]]; then
  note "Kibana credentials configured."
  info "Redis is provided locally in the Hive stack."

  # Confirmation
  if [[ "$AUTO_CONFIRM" != "yes" ]]; then
    read -rp "Installation mode HIVE. Continue? (y/N): " confirm
    if [[ "${confirm,,}" != "y" && "${confirm,,}" != "yes" ]]; then
      info "Installation aborted."
      exit $EXIT_QUIT
    fi
  else
    info "Automatic confirmation enabled - continuing with Hive installation"
  fi

  TARGET_DIR="$HOME/hive"
  ensure_dir "$TARGET_DIR"
  ensure_dir "$TARGET_DIR/env"

  # RL-Agent-ENV
  info "Creating RL-Agent configuration..."
  cat >"$TARGET_DIR/env/rl-agent.env" <<EOF
LOGLEVEL=INFO
WINDOW_SEC=300
TRANSFORM_DEST=features_madcat
HONEYPOD_NS=default
HONEYPOD_TTL_SEC=1800
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_CHANNEL=honeypod-map
REWARD_ALPHA=1.0
REWARD_BETA=0.05
CPU_WEIGHT=0.7
MEM_WEIGHT=0.3
ES_STARTUP_DELAY=20
ES_HOST=http://elasticsearch:9200
EOF

  # ADLAH ENV
  info "Creating ADLAH configuration..."
  cat >"$ENV_FILE" <<EOF
ADLAH_TYPE=HIVE
ADLAH_USER=$KIBANA_USER
KIBANA_ENCRYPTION_KEY=$KIBANA_ENCRYPTION_KEY
EOF
  run_or_die cp "$ENV_FILE" "$TARGET_DIR/.env"

  info "Copying Hive files..."
  if ! rsync -a --no-perms --chown=lukas:lukas ./hive/ "$TARGET_DIR/"; then
    die "Error copying Hive files (Exit code: $?)"
  fi
  
  # Check if copying was successful
  check_path_exists "$TARGET_DIR/docker-compose.yml" "Hive Docker Compose configuration in target directory"

  info "Generating htpasswd file..."
  if ! check_command htpasswd; then
    run_or_die sudo apt install -y apache2-utils
  fi
  run_or_die mkdir -p "$TARGET_DIR/nginx"
  # If old htpasswd exists as directory by mistake
  cleanup_maybe_dir "$TARGET_DIR/nginx/htpasswd"
  run_or_die htpasswd -mbc "$TARGET_DIR/nginx/htpasswd" "$KIBANA_USER" "$KIBANA_PASSWORD"

  info "Generating TLS certificate..."
  CERT_DIR="$TARGET_DIR/nginx/certs"
  ensure_dir "$CERT_DIR"
  # Remove old artifacts (file or directory)
  cleanup_maybe_dir "$CERT_DIR/selfsigned.key"
  cleanup_maybe_dir "$CERT_DIR/selfsigned.crt"
  run_or_die openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$CERT_DIR/selfsigned.key" \
      -out   "$CERT_DIR/selfsigned.crt" \
      -subj "/CN=localhost"

  # Check if Kibana configuration exists
  if [[ -f "$TARGET_DIR/kibana/dist/kibana.yml" ]]; then
    sed -i "s|__ENCRYPTION_KEY__|$KIBANA_ENCRYPTION_KEY|g" "$TARGET_DIR/kibana/dist/kibana.yml" || warn "Could not update Kibana configuration"
  else
    warn "Kibana configuration file not found: $TARGET_DIR/kibana/dist/kibana.yml"
  fi

  info "Starting Hive stack..."
  run_or_die sudo systemctl enable docker
  run_or_die sudo systemctl start docker
  run_compose_stack "$TARGET_DIR"

  info "Hive is ready: http://<your-ip>:64297"

# ── SENSOR Installation ──────────────────────────────────────────────────────
else # This covers only the 'sensor' case, as the type was validated
  note "Sensor configuration configured."
  # Interface validation was already performed in validate_installation_parameters

  # Confirmation
  if [[ "$AUTO_CONFIRM" != "yes" ]]; then
    read -rp "Installation mode SENSOR. Continue? (y/N): " confirm
    if [[ "${confirm,,}" != "y" && "${confirm,,}" != "yes" ]]; then
      info "Installation aborted."
      exit $EXIT_QUIT
    fi
  else
    info "Automatic confirmation enabled - continuing with Sensor installation"
  fi

  MADCAT_IP=$(ip -4 addr show "$MADCAT_IF" \
              | awk '/inet / {print $2}' | cut -d/ -f1)
  info "MADCAT uses IP $MADCAT_IP"

  TARGET_DIR="$HOME/sensor"
  run_or_die mkdir -p "$TARGET_DIR"

  # ENV-Datei schreiben
  info "Creating Sensor configuration..."
  cat >"$ENV_FILE" <<EOF
ADLAH_TYPE=SENSOR
HIVE_IP=$HIVE_IP
MADCAT_INTERFACE=$MADCAT_IF
MADCAT_IP=$MADCAT_IP
MGMT_INTERFACE=$MGMT_IF
EOF
  run_or_die cp "$ENV_FILE" "$TARGET_DIR/.env"

  info "Copying Sensor files..."
  if ! rsync -a --no-perms --chown=lukas:lukas sensor/ "$TARGET_DIR/"; then
    die "Error copying Sensor files (Exit code: $?)"
  fi
  
  # NEW: Ensure redirect script is executable
  if [ -f "$TARGET_DIR/redirect_attacker.sh" ]; then
    chmod +x "$TARGET_DIR/redirect_attacker.sh"
    info "Made redirect script executable."
  fi

  # Prüfe ob Kopieren erfolgreich war
  check_path_exists "$TARGET_DIR/docker-compose.yml" "Sensor Docker Compose configuration in target directory"
  
  run_or_die sudo mkdir -p /var/log/madcat && sudo chown "$USER_NAME":"$USER_NAME" /var/log/madcat

  # Path fix for run script
  MADCAT_RUN="$TARGET_DIR/madcat/scripts/run_madcat.sh"
  if [[ -f $MADCAT_RUN ]]; then
    info "Adjusting MADCAT run script..."
    # 1) Path fix & remove sudo
    run_or_die sed -i 's|/opt/madcat/data|/var/log/madcat|g; s/\bsudo\b //g' "$MADCAT_RUN"
    # 2) NEW → Inject interface parameter
    run_or_die sed -i -E 's|^(MADCAT_CMD="madcat )|\1-i ${MADCAT_INTERFACE} |' "$MADCAT_RUN"
    run_or_die chmod +x "$MADCAT_RUN"
  fi

  info "Installing SSH server..."
  run_or_die sudo apt install -y openssh-server
  run_or_die sudo systemctl enable ssh
  run_or_die sudo systemctl start ssh

  info "Starting Sensor stack..."
  run_or_die sudo systemctl enable docker
  run_or_die sudo systemctl start docker
  run_compose_stack "$TARGET_DIR"

  if docker exec madcat ps aux | grep madcat | grep -v grep; then
    info "Sensor is ready. Now run deploy.sh on the Hive."
  else
    warn "MADCAT process might not be running correctly"
  fi
fi

info "Installation completed successfully!"
