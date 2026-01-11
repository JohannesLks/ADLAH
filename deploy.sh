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

set -Eeuo pipefail
shopt -s inherit_errexit

###############################################################################
# Colors & Helpers
###############################################################################
C0='\e[0m'; C1='\e[36m'; C2='\e[32m'; C3='\e[33m'; C4='\e[31m'
info () { echo -e "${C2}[deploy]${C0} $*"; }
note () { echo -e "${C1}[deploy]${C0} $*"; }
warn () { echo -e "${C3}[deploy] $*${C0}"; }
die  () { echo -e "${C4}[deploy] $*${C0}" >&2; exit 1; }

###############################################################################
# General Variables
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$SCRIPT_DIR/k8s"
ENV_FILE="$HOME/.adlah_env"
CERT_DIR="$HOME/.adlah_certs"
FILEBEAT_CERT_DIR="$HOME/filebeat-certs"
HIVE_STACK="$HOME/hive"

K3S_DIR="$HOME/.adlah_k3s"                      # Storage for installer/binary
K3S_VERSION="${K3S_VERSION:-v1.30.1+k3s1}"      # Desired version
K3S_INST="$K3S_DIR/install_k3s.sh"
K3S_BIN="$K3S_DIR/k3s"

SSH_PORTS=(${ADLAH_SSH_PORTS:-22})              # multiple ports possible
SSH_OPT=${ADLAH_SSH_KEY:+-i "$ADLAH_SSH_KEY"}   # optional private key
SSH_PORT_CFG="${SSH_PORTS[0]}"
SSH_KEY_OPT=${ADLAH_SSH_KEY:+-i ${ADLAH_SSH_KEY}}

# SSH key permissions are now handled by the calling script (reinstall.sh)

###############################################################################
# SSH Hostkey Protection
###############################################################################
ensure_known_host() {
  local host="$1" port="${2:-22}"
  note "Checking SSH hostkey for $host:$port..."
  ssh-keygen -R "[$host]:$port" &>/dev/null || true
  ssh-keyscan -p "$port" -H "$host" >> ~/.ssh/known_hosts 2>/dev/null || {
    warn "ssh-keyscan failed for $host:$port."
  }
}

###############################################################################
# SSH & SCP Wrapper (with port failover)
###############################################################################
retry_ssh() {
  local remote="$1"; shift
  local host="${remote#*@}"
  local script="$*"

  for p in "${SSH_PORTS[@]}"; do
    ensure_known_host "$host" "$p"
    note "SSH  → $remote (Port $p)…"

    if ssh -tt -o BatchMode=yes -o ConnectTimeout=5 -p "$p" $SSH_OPT \
          "$remote" bash -s <<EOF; then
set -Eeuo pipefail
export PS4='+ [\$(date "+%H:%M:%S")] \$LINENO: '
exec 2> >(tee /tmp/remote-stderr.log >&2)
exec 1> >(tee /tmp/remote-stdout.log)
set -x
$script
exit 0
EOF
      return 0
    else
      warn "SSH command failed on $remote"
    fi
  done

  die "SSH command could not be executed successfully on any port."
}

retry_scp() {
  local -a srcs=("${@:1:$#-1}")
  local dest="${@: -1}"

  # If target **no** ':' contains ➟ local path ➟ direct scp
  if [[ $dest != *:* ]]; then
    scp -o BatchMode=yes -o ConnectTimeout=5 "${srcs[@]}" "$dest"
    return
  fi

  local remote="${dest%%:*}"
  local host="${remote#*@}"
  for p in "${SSH_PORTS[@]}"; do
    ensure_known_host "$host" "$p"
    note "SCP  → $dest (Port $p)…"
    # Force correct permissions on the key right before use
    if [[ -n "${ADLAH_SSH_KEY-}" && -f "$ADLAH_SSH_KEY" ]]; then
        chmod 600 "$ADLAH_SSH_KEY"
    fi
    if scp -o BatchMode=yes -o ConnectTimeout=5 -P "$p" $SSH_OPT \
          "${srcs[@]}" "$dest"; then
      return 0
    fi
    warn "Port $p failed."
  done
  die "SCP to $dest not possible."
}

###############################################################################
# Hive Preparation
###############################################################################
[[ -f $ENV_FILE ]] || die "$ENV_FILE missing (HIVE-VM?)"
grep -q 'ADLAH_TYPE=HIVE' "$ENV_FILE" || \
  die "This script must only run on a Hive VM!"

info "stopping local rl-agent (if present)..."
docker compose -f "$HIVE_STACK/docker-compose.yml" rm -fs rl-agent &>/dev/null || true

# Cleanup: k3s must NOT run on the Hive
if systemctl is-active --quiet k3s; then
  warn "k3s is running on the Hive VM - this should not happen! Stopping it..."
  sudo systemctl stop k3s || true
  sudo systemctl disable k3s || true
fi

# Port 6443 check only for Cluster mode (will be executed later)

# CLI Parsing (directly after functions, before any logic!)
MODE= CLUSTER_IP= CLUSTER_USER= GRAF_PWD= HONEYPOD_RANGE="10.2.0.0/16"
usage() { cat <<USAGE
Usage:
  $0 --cluster --ip <IP> --user <ssh-user> [--grafana-pass <PW>] [--honeypod-range <CIDR>]
  $0 --sensor  --ip <IP> --user <ssh-user>

Flags/Parameters:
  --cluster             Cluster Mode (Hive → Cluster)
  --sensor              Sensor Mode (Hive → Sensor)
  --ip <IP>             Target IP of Cluster/Sensor VM
  --user <ssh-user>     SSH Username for Target VM
  --grafana-pass <PW>   (optional, Cluster) Password for Grafana Admin
  --honeypod-range <CIDR> (optional, Cluster) Honeypod IP Range, e.g. 10.2.0.0/16 (Default: 10.2.0.0/16)
  -h, --help            Show this help

Examples:
  $0 --cluster --ip 10.1.0.10 --user johannes --honeypod-range 10.2.0.0/16
  $0 --sensor --ip 10.1.0.20 --user johannes
USAGE
exit 0; }

eval set -- "$(getopt -o h --long help,cluster,sensor,ip:,user:,grafana-pass:,honeypod-range: -- "$@")"
while true; do
  case $1 in
    --cluster) MODE=CLUSTER;;
    --sensor)  MODE=SENSOR;;
    --ip)      CLUSTER_IP=$2; shift;;
    --user)    CLUSTER_USER=$2; shift;;
    --grafana-pass) GRAF_PWD=$2; shift;;
    --honeypod-range) HONEYPOD_RANGE=$2; shift;;
    -h|--help) usage ;;
    --) shift; break ;;
    *) usage ;;
  esac; shift
done

# ... from here on actual logic ...

[[ $MODE ]]        || usage

# Different prompts depending on mode
if [[ $MODE == SENSOR ]]; then
  [[ $CLUSTER_IP ]]  || read -rp "Sensor-IP: " CLUSTER_IP
  [[ $CLUSTER_USER ]]|| CLUSTER_USER="lukas"
else
  [[ $CLUSTER_IP ]]  || read -rp "Cluster-IP: " CLUSTER_IP
  [[ $CLUSTER_USER ]]|| CLUSTER_USER="lukas"
  [[ $MODE == CLUSTER && -z $GRAF_PWD ]] && GRAF_PWD=$(openssl rand -base64 16)
fi

info "Mode=$MODE  Host=$CLUSTER_IP  User=$CLUSTER_USER"

###############################################################################
# k3s Installer + Binary (load once onto Hive)
###############################################################################
mkdir -p "$K3S_DIR"

if [[ ! -f $K3S_INST ]]; then
  info "downloading k3s installer..."
  curl -fSL https://get.k3s.io -o "$K3S_INST"
  chmod +x "$K3S_INST"
fi

if [[ ! -f $K3S_BIN ]]; then
  ARCH=$(uname -m)
  info "downloading k3s binary $K3S_VERSION ($ARCH)..."
  curl -fSL \
    "https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s" \
    -o "$K3S_BIN"
  chmod +x "$K3S_BIN"
fi

###############################################################################
# Generate certificates (if not present)
###############################################################################
mkdir -p "$CERT_DIR"
if [[ ! -f $CERT_DIR/logstash.crt || ! -f $CERT_DIR/logstash.key ]]; then
  info "creating self-signed Logstash TLS certificate..."
  openssl req -nodes -x509 -sha512 -newkey rsa:4096 \
    -days 365 -keyout "$CERT_DIR/logstash.key" -out "$CERT_DIR/logstash.crt" \
    -subj "/C=DE/O=ADLAH" \
    -addext "subjectAltName = IP:$(hostname -I | awk '{print $1}')" >/dev/null
fi

###############################################################################
# SENSOR-MODE
###############################################################################
if [[ $MODE == SENSOR ]]; then
  mkdir -p "$FILEBEAT_CERT_DIR"
  
  # Check if certificates exist
  if [[ ! -f "$CERT_DIR/logstash.crt" || ! -f "$CERT_DIR/logstash.key" ]]; then
    die "Certificates not found in $CERT_DIR. Run certificate generation first."
  fi
  
  cp "$CERT_DIR"/logstash.{crt,key} "$FILEBEAT_CERT_DIR/"
  
  # Ensure certificates have correct permissions
  # For SCP, files must be readable
  chmod 644 "$CERT_DIR/logstash.crt"
  chmod 644 "$CERT_DIR/logstash.key"
  
  # Show current permissions for debugging
  info "Certificate permissions:"
  ls -la "$CERT_DIR"/logstash.*
  
  # Create directory on sensor with correct permissions
  retry_ssh "$CLUSTER_USER@$CLUSTER_IP" "rm -rf ~/adlah_certs && mkdir -p ~/adlah_certs && ls -la ~/adlah_certs"
  
  # Copy certificates
  retry_scp "$CERT_DIR/logstash.crt" "$CERT_DIR/logstash.key" \
            "$CLUSTER_USER@$CLUSTER_IP:~/adlah_certs/"
  
  # Set correct permissions on sensor
  retry_ssh "$CLUSTER_USER@$CLUSTER_IP" "chmod 644 ~/adlah_certs/logstash.crt && chmod 600 ~/adlah_certs/logstash.key"
  
  info "Sensor TLS onboarding completed"
  exit 0
fi

###############################################################################
# CLUSTER-MODE
###############################################################################

# Ensure port 6443 is free (only for Cluster mode)
if sudo lsof -i :6443 &>/dev/null; then
  warn "Port 6443 is occupied. Cleaning..."
  sudo fuser -k 6443/tcp || true
  sleep 2
fi

info "Grafana-Passwort: $GRAF_PWD"
HIVE_IP=$(hostname -I | awk '{print $1}')
export HIVE_IP
HIVE_IP_FOR_CLUSTER=${ADLAH_HIVE_IP_OVERRIDE:-$HIVE_IP}

if [[ -z $HIVE_IP_FOR_CLUSTER ]]; then
  die "HIVE_IP_FOR_CLUSTER could not be determined. Set ADLAH_HIVE_IP_OVERRIDE if needed."
fi
note "Hive IP for Cluster communication: $HIVE_IP_FOR_CLUSTER"

# Hostkey check on all allowed SSH ports
for port in "${SSH_PORTS[@]}"; do ensure_known_host "$CLUSTER_IP" "$port"; done

# Copy certificate + k3s files to Cluster VM
retry_scp "$CERT_DIR/logstash.crt" "$CERT_DIR/logstash.key" "$CLUSTER_USER@$CLUSTER_IP:/tmp/"
retry_scp "$K3S_INST" "$K3S_BIN"            "$CLUSTER_USER@$CLUSTER_IP:/tmp/"

# Prepare honeypod-pool.yaml for later copying
export HONEYPOD_RANGE
envsubst '$HONEYPOD_RANGE' < "$K8S_DIR/honeypod-pool.yaml" > /tmp/honeypod-pool.yaml

###############################################################################
# COMPLETE KUBERNETES CLEANUP - Clean reinstall
###############################################################################
info "🧹 Performing complete Kubernetes cleanup for clean reinstallation..."

# First, try to connect and clean up everything on the cluster
cleanup_ok=0
for p in "${SSH_PORTS[@]}"; do
  ensure_known_host "$CLUSTER_IP" "$p"
  note "Cleanup → $CLUSTER_USER@$CLUSTER_IP (Port $p)…"
  
  if ssh -T -o BatchMode=yes -o ConnectTimeout=5 -p "$p" $SSH_OPT \
        "$CLUSTER_USER@$CLUSTER_IP" bash -s <<'CLEANUP_EOF'
set -Eeuo pipefail
log() { echo -e "\e[34m[cleanup] $*\e[0m"; }

log "🧹 Starting complete Kubernetes cleanup..."

# Stop k3s service
log "Stopping k3s Service..."
sudo systemctl stop k3s || true
sudo systemctl disable k3s || true

# Kill any remaining k3s processes
log "Terminating all k3s processes..."
sudo pkill -f k3s || true
sudo pkill -f containerd || true

# Clean up k3s data directories
log "Deleting k3s data directories..."

# First stop all pods and containers
log "Stopping all Kubernetes pods..."
if command -v kubectl >/dev/null 2>&1; then
  kubectl delete pods --all --force --grace-period=0 2>/dev/null || true
  kubectl delete deployments --all --force --grace-period=0 2>/dev/null || true
  kubectl delete daemonsets --all --force --grace-period=0 2>/dev/null || true
fi

# Wait briefly so pods can terminate
sleep 5

# Then delete directories
sudo rm -rf /var/lib/rancher/k3s || true
sudo rm -rf /etc/rancher/k3s || true

# Clean up kubelet directories carefully (with umount if needed)
log "Cleaning up kubelet directories..."
if mountpoint -q /var/lib/kubelet/pods 2>/dev/null; then
  sudo umount /var/lib/kubelet/pods/*/volumes/* 2>/dev/null || true
fi
sudo rm -rf /var/lib/kubelet || true
sudo rm -rf /var/lib/cni || true
sudo rm -rf /var/lib/calico || true
sudo rm -rf /opt/cni || true

# Clean up network interfaces and routes
log "Cleaning up network interfaces..."
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true
sudo ip link delete cali+ 2>/dev/null || true
sudo ip route del 10.42.0.0/16 2>/dev/null || true
sudo ip route del 10.43.0.0/16 2>/dev/null || true

# Clean up iptables rules
log "Cleaning up iptables rules..."
sudo iptables -t nat -F || true
sudo iptables -t mangle -F || true
sudo iptables -F || true
sudo iptables -X || true

# Clean up Docker/containerd
log "Cleaning up container runtime..."
sudo systemctl stop containerd || true
sudo systemctl disable containerd || true
sudo rm -rf /var/lib/containerd || true

# Clean up any remaining pods/containers
log "Terminating all remaining containers..."
sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true

# Clean up systemd services
log "Cleaning up Systemd Services..."
sudo systemctl reset-failed || true

# Clean up any remaining files
log "Cleaning up remaining files..."
sudo rm -rf /tmp/k3s* || true
sudo rm -rf /tmp/calico* || true
sudo rm -rf /tmp/metallb* || true

# Clean up user directories
log "Cleaning up user directories..."
rm -rf ~/.kube || true
rm -rf ~/.config/helm || true

log " Kubernetes cleanup completed"
CLEANUP_EOF
  then
    cleanup_ok=1
    break
  else
    warn "  Cleanup on $CLUSTER_USER@$CLUSTER_IP failed"
  fi
done

if [[ $cleanup_ok -ne 1 ]]; then
  warn "  Cleanup failed, but continuing with installation..."
fi

# Copy all required files AFTER cleanup
note "Transferring all required files after cleanup..."
retry_scp "$K3S_INST" "$K3S_BIN" "$CLUSTER_USER@$CLUSTER_IP:/tmp/"
retry_scp "$K8S_DIR/calico.yaml" "$CLUSTER_USER@$CLUSTER_IP:/tmp/calico.yaml"
retry_scp "/tmp/honeypod-pool.yaml" "$CLUSTER_USER@$CLUSTER_IP:/tmp/honeypod-pool.yaml"
note "Transferring Redis manifests..."
retry_scp "$K8S_DIR/redis-pod.yaml" "$K8S_DIR/redis-service.yaml" "$CLUSTER_USER@$CLUSTER_IP:/tmp/"
note "Transferring Orchestrator files..."
retry_scp -r "$SCRIPT_DIR/orchestrator" "$CLUSTER_USER@$CLUSTER_IP:/tmp/"
 
 ###############################################################################
# Remote-Bootstrap-Skript (offline)
###############################################################################
TMP_SCRIPT=$(mktemp)
cat > "$TMP_SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo -e "\e[34m[remote] $*\e[0m"; }

trap 'ec=$?; cmd=$BASH_COMMAND;
      echo -e "\e[31m[remote] Error on line $LINENO: »$cmd« (Exit $ec)\e[0m" >&2' ERR

exec 2> >(tee /tmp/bootstrap.log >&2)
set -x

log "Starting Cluster Bootstrap..."

log "Installing required packages (fuser, iptables, docker)..."
sudo apt-get update || true
sudo apt-get remove -y containerd.io || true
sudo apt-get install -y psmisc iptables docker.io

# Fix for non-interactive shells: Set necessary environment variables for systemd/dbus
if [[ -z "${DBUS_SESSION_BUS_ADDRESS-}" ]]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

if [[ -z "${XDG_RUNTIME_DIR-}" ]]; then
  export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

#############################################################################
# -1) Vorherige k3s-Prozesse und blockierende Ports bereinigen
#############################################################################
log "Cleaning up potential remnants from previous runs..."
sudo systemctl stop k8s-api-tunnel.service || true
sudo fuser -k 6443/tcp || true
# Wait a moment to ensure port is released
sleep 2

#############################################################################
# 0) Enable Kernel parameters for Netfilter / Forwarding
#############################################################################
sudo modprobe br_netfilter
sudo sh -c 'echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables'
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'

#############################################################################
# 1) Install k3s (in /usr/local/bin) offline
#############################################################################
# Check first if k3s binary exists, install if needed.
if ! command -v k3s >/dev/null; then
  log "k3s binary not found, installing..."
  if [[ -f /tmp/k3s ]]; then
    sudo cp /tmp/k3s /usr/local/bin/k3s
    sudo chmod +x /usr/local/bin/k3s
  else
    log "k3s binary not found in /tmp. Aborting."
    exit 1
  fi
else
  log "k3s binary already present."
fi

# Check separately if Kubeconfig file exists. If not, run
# k3s installer to create configuration and systemd service.
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
  log "k3s.yaml already exists."
  
  # Check if k3s configuration contains correct TLS-SAN
  if [ -f /etc/rancher/k3s/config.yaml ] && grep -q "127.0.0.1" /etc/rancher/k3s/config.yaml; then
    log "k3s configuration already contains 127.0.0.1 as TLS-SAN."
  else
          log "k3s configuration needs update (TLS-SAN for 127.0.0.1 missing)."

    # Create or update k3s configuration
    sudo mkdir -p /etc/rancher/k3s
    cat <<K3SCONFIG | sudo tee /etc/rancher/k3s/config.yaml > /dev/null
tls-san:
  - $CLUSTER_IP
  - 127.0.0.1
  - host.docker.internal
disable:
  - traefik
write-kubeconfig-mode: "0644"
K3SCONFIG
    
    log "Deleting old certificates and restarting k3s..."
    sudo rm -rf /var/lib/rancher/k3s/server/tls/*.crt /var/lib/rancher/k3s/server/tls/*.key
    sudo systemctl restart k3s.service
    
    log "Waiting 15 seconds for k3s to generate new certificates..."
    sleep 15
  fi
else
  log "k3s.yaml not found, installing k3s..."
  log "TLS-SAN IP: $CLUSTER_IP"
  sudo env INSTALL_K3S_SKIP_DOWNLOAD=true \
       INSTALL_K3S_EXEC="--flannel-backend=none --disable-network-policy --disable traefik --tls-san $CLUSTER_IP --tls-san 127.0.0.1 --tls-san host.docker.internal --write-kubeconfig-mode 644" \
       /tmp/install_k3s.sh || { journalctl -xeu k3s.service; exit 1; }
fi

# Ensure k3s is running and start if needed
if ! sudo systemctl is-active --quiet k3s.service; then
  log "k3s service is not active. Starting..."
  sudo systemctl start k3s.service || {
          log "k3s could not be started. Check logs..."
    sudo journalctl -n 50 --no-pager -u k3s.service
    exit 1
  }
fi

# Wait briefly for k3s to fully start
sleep 5

#############################################################################
# 2) Configure Kubeconfig
#############################################################################
log "Configuring Kubeconfig"
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config || true
sudo chown "$USER:$USER" ~/.kube/config
export KUBECONFIG=~/.kube/config

log "Waiting for Kubernetes API Server (max. 5 minutes)..."
for i in {1..60}; do
  # 'kubectl version' is a lightweight check to verify API availability
  if kubectl version &>/dev/null; then
    log "Kubernetes API is ready."
    break
  fi
  log "... API not yet ready, waiting 5 seconds ($i/60)"
  sleep 5
done

# Final check if API is reachable, otherwise abort
if ! kubectl version &>/dev/null; then
  log "Kubernetes API not reachable after 5 minutes. Check k3s logs with 'sudo journalctl -u k3s'."
  exit 1
fi

#############################################################################
# 3a) Install and configure Calico CNI
#############################################################################
log "Installing Calico CNI..."
sudo kubectl apply -f /tmp/calico.yaml

log "Waiting for Calico rollout (can take a few minutes)..."
# Wait until DaemonSet is rolled out on all nodes.
if ! sudo kubectl -n kube-system rollout status ds/calico-node --timeout=240s; then
    log "Calico rollout failed. Checking pods:"
    sudo kubectl -n kube-system get pods -o wide
    exit 1
fi
log "Calico is ready."

log "Configuring Calico IP Pools..."
sudo kubectl apply -f /tmp/honeypod-pool.yaml
log "Disabling default IP pool..."
sudo kubectl patch ippool default-ipv4-ippool --type merge -p '{"spec": {"disabled": true}}'

log "Creating honeypod namespace for clean network separation..."
sudo kubectl create namespace honeypod --dry-run=client -o yaml | sudo kubectl apply -f -

#############################################################################
# 3c) Install Redis Pod & Service
#############################################################################
log "Installing Redis..."
sudo kubectl apply -f /tmp/redis-pod.yaml
sudo kubectl apply -f /tmp/redis-service.yaml

log "Waiting for Redis Pod..."
if ! sudo kubectl wait --for=condition=ready pod/redis -n honeypod --timeout=120s; then
 log "Redis pod not ready. Checking pods:"
 sudo kubectl get pods -n honeypod -l name=redis
 exit 1
fi
log "Redis is ready."

#############################################################################
# 3d) Install Honeypot Orchestrator
#############################################################################
log "Installing Honeypot Orchestrator..."
if [ -d "/tmp/orchestrator" ]; then
  log "Building Orchestrator Docker Image..."
  sudo docker build -t honeypot-orchestrator:latest /tmp/orchestrator
  
  log "Importing Orchestrator Image into k3s..."
  sudo docker save honeypot-orchestrator:latest | sudo k3s ctr images import -

  log "Applying Orchestrator Kubernetes configuration..."
  sudo kubectl apply -f /tmp/orchestrator/rbac.yaml
  sudo kubectl apply -f /tmp/orchestrator/deployment.yaml
  
  log "Waiting for Orchestrator rollout..."
  if ! sudo kubectl rollout status deployment/honeypot-orchestrator --timeout=120s; then
    log "Orchestrator rollout failed. Checking pods:"
    sudo kubectl get pods -l app=honeypot-orchestrator
    exit 1
  fi
  log "Honeypot Orchestrator is ready."
else
  log "Orchestrator directory /tmp/orchestrator not found. Skipping."
fi
 
 #############################################################################
 # 3c) Install and configure MetalLB LoadBalancer
#############################################################################
log "Cleaning up old pods to free resources..."
sudo kubectl delete pods --all-namespaces --field-selector=status.phase=Pending --ignore-not-found=true || true
sudo kubectl delete pods --all-namespaces --field-selector=status.phase=Failed --ignore-not-found=true || true

log "Checking available resources..."
sudo kubectl top nodes || true
sudo kubectl get nodes -o wide

# MetalLB skipped
log "Using NodePort services for Honeypods..."
SKIP_METALLB=true

# Honeypods will be exposed via hostPort
log "Traffic routing via iptables on Sensor"

#############################################################################
# 3b) Install Prometheus Stack for Kubernetes metrics
#############################################################################
# We use kube-prometheus-stack (Prometheus Operator, Exporter, Dashboards)
log "Installing/updating Prometheus Stack (kube-prometheus-stack)..."
# Install Helm if not present
if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update

#
# ---------- Pending-Release-Cleaner ----------------------------------------
#
clean_pending() {
  local rel=$1 ns=$2
  if helm status "$rel" -n "$ns" -o json | jq -e '.info.status | test("pending")' &>/dev/null; then
    log " Release '$rel' in Namespace '$ns' is in 'pending' status. Trying rollback/uninstall..."
    
    # Find last successful revision
    local last_ok=$(helm history "$rel" -n "$ns" -o json | \
                    jq '[.[] | select(.status | test("deployed"))][-1].revision // 0')

    if [[ "$last_ok" -gt 0 ]]; then
      log "↩️  Rollback for '$rel' to revision $last_ok"
      helm rollback "$rel" "$last_ok" -n "$ns" --wait --cleanup-on-fail || \
        log "💣 Rollback failed, trying uninstall..." && helm uninstall "$rel" -n "$ns" || true
    else
      log "🗑  No successful revision for '$rel' found – uninstalling."
      helm uninstall "$rel" -n "$ns" || true
    fi
  fi
}

clean_pending prom monitoring

#
# ---------- End Pending-Release-Cleaner -----------------------------------
#
#############################################################################
# ⛏️  Clean up old honeypod pods/deployments (CrashLoop / Pending Blocker)
#############################################################################
log "Cleaning up old honeypod deployments & pods (CrashLoop/Pending)..."

# Ensure all old honeypods with label are gone
kubectl delete deployment,pod -n default -l app=honeypod --ignore-not-found=true --force --grace-period=0 || true

# Skip Prometheus/Grafana installation (causes timeouts)
log "Skipping Prometheus/Grafana installation for faster deployment..."
log "Grafana can be installed manually later if needed."

# Prometheus Service wait loop skipped (Service not installed)

#############################################################################
# 3d2) Second Interface for Honeypod-Network (dynamic)
#############################################################################
log "Configuring second interface for Honeypod network (${HONEYPOD_RANGE})..."

HONEYPOD_IF="ens5"
HONEYPOD_NET="${HONEYPOD_RANGE}"
# Calculate Gateway IP from CIDR (first usable IP)
HONEYPOD_GW=$(echo "${HONEYPOD_RANGE}" | sed 's|/.*||' | sed 's|\.[0-9]*$|.1|')

# Check if interface exists
if ip link show $HONEYPOD_IF >/dev/null 2>&1; then
    log " Interface $HONEYPOD_IF found"
    # Assign IP if not present (with correct subnet mask)
    HONEYPOD_MASK=$(echo "${HONEYPOD_RANGE}" | sed 's|.*/||')
    if ! ip addr show $HONEYPOD_IF | grep -q "$HONEYPOD_GW"; then
        sudo ip addr add $HONEYPOD_GW/$HONEYPOD_MASK dev $HONEYPOD_IF
        log " IP $HONEYPOD_GW/$HONEYPOD_MASK added to $HONEYPOD_IF"
    fi
    sudo ip link set $HONEYPOD_IF up
else
    log " Interface $HONEYPOD_IF not found! Please check."
    exit 1
fi

# Enable IP forwarding
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null

log " Honeypod Interface $HONEYPOD_IF ($HONEYPOD_GW/$HONEYPOD_MASK) ready"

#############################################################################
# 3e) Honeypod Filebeat Config & Certificate Secret
#############################################################################
log "Creating ConfigMap filebeat-honeypod & Secret filebeat-certs (idempotent)..."

cat <<CM >/tmp/filebeat-honeypod.yml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /home/cowrie/log/*.log
      - /home/cowrie/log/*.json
    fields:
      src_ip: \${SRC_IP}
    json.keys_under_root: true
    json.add_error_key: true

output.logstash:
  hosts: ["${HIVE_IP}:5044"]
  ssl.enabled: false
CM


# HIVE_IP_FOR_CLUSTER is required for creating the ConfigMap
export HIVE_IP_FOR_CLUSTER

# Create Honeypod namespace for clean separation
log "Creating Honeypod namespace for clean network separation..."
kubectl create namespace honeypod --dry-run=client -o yaml | kubectl apply -f -

# Delete existing resources and recreate to resolve errors
log "Deleting old Honeypod resources (ConfigMap, Secret)..."
kubectl -n honeypod delete configmap filebeat-honeypod --ignore-not-found=true
kubectl -n honeypod delete secret filebeat-certs --ignore-not-found=true

log "Creating ConfigMap filebeat-honeypod & Secret filebeat-certs in honeypod namespace..."

# Replace variable in temporary file
envsubst '$HIVE_IP_FOR_CLUSTER' < /tmp/filebeat-honeypod.yml > /tmp/filebeat-honeypod.yml.tmp
mv /tmp/filebeat-honeypod.yml.tmp /tmp/filebeat-honeypod.yml

# Create ConfigMap from processed file (in honeypod namespace)
kubectl -n honeypod create configmap filebeat-honeypod \
  --from-file=filebeat.yml=/tmp/filebeat-honeypod.yml \
  --dry-run=client -o yaml | kubectl apply -f -

# Create Secret for Filebeat Certs (CA + Key) in honeypod namespace
kubectl -n honeypod create secret generic filebeat-certs \
  --from-file=/tmp/logstash.crt \
  --from-file=/tmp/logstash.key \
  --dry-run=client -o yaml | kubectl apply -f -

rm -f /tmp/filebeat-honeypod.yml
rm -f /tmp/filebeat-honeypod.yml.tmp

EOF

# Execute the remote bootstrap script
remote_ok=0
for p in "${SSH_PORTS[@]}"; do
  ensure_known_host "$CLUSTER_IP" "$p"
  note "SSH  → $CLUSTER_USER@$CLUSTER_IP (Port $p)…"
  
  # Export all required variables so they are available to the remote shell
  if ssh -T -o BatchMode=yes -o ConnectTimeout=5 -p "$p" $SSH_OPT \
        "$CLUSTER_USER@$CLUSTER_IP" env \
        "CLUSTER_IP=$CLUSTER_IP" \
        "GRAF_PWD=$GRAF_PWD" \
        "HIVE_IP=$HIVE_IP" \
        "HIVE_IP_FOR_CLUSTER=$HIVE_IP_FOR_CLUSTER" \
        "HONEYPOD_RANGE=$HONEYPOD_RANGE" \
        "SKIP_METALLB=${SKIP_METALLB:-false}" \
        "MODE=$MODE" \
        "CLUSTER_USER=$CLUSTER_USER" \
        "SENSOR_IP=$CLUSTER_IP" \
        "SENSOR_USER=$CLUSTER_USER" \
        "SENSOR_SSH_KEY=/app/secrets/id_rsa" \
        bash -s < "$TMP_SCRIPT"; then
    remote_ok=1
    break
  else
    warn "  SSH command via $CLUSTER_USER@$CLUSTER_IP failed"
  fi
done

if [[ $remote_ok -ne 1 ]]; then
  die " Remote bootstrap on $CLUSTER_IP failed. Aborting."
fi

# Ensure target directory exists and is writable, then copy kubeconfig from cluster to hive
# If directory exists and we can't write to it, we need sudo to fix it
if [[ -d "$HIVE_STACK/cluster_kubeconfig" ]]; then
  if [[ ! -w "$HIVE_STACK/cluster_kubeconfig" ]]; then
    warn "cluster_kubeconfig exists, but is not writable. Trying to delete with sudo..."
    sudo rm -rf "$HIVE_STACK/cluster_kubeconfig" || die "Cannot delete cluster_kubeconfig. Please delete manually with 'sudo rm -rf $HIVE_STACK/cluster_kubeconfig'."
  fi
fi

mkdir -p "$HIVE_STACK/cluster_kubeconfig"

# Explicitly remove the target to ensure it's created as a file
# rm -rf "$HIVE_STACK/cluster_kubeconfig/config_host" # This was causing the path to be a directory

# Get Kubeconfig
info "Fetching Kubeconfig from cluster..."

kubeconfig_ok=0
for p in "${SSH_PORTS[@]}"; do
  ensure_known_host "$CLUSTER_IP" "$p"
  note "Fetching kubeconfig → $CLUSTER_USER@$CLUSTER_IP (Port $p)…"
  # Use ssh+cat for robust file download, avoiding scp directory ambiguity
  if ssh -o BatchMode=yes -o ConnectTimeout=5 -p "$p" $SSH_OPT \
        "$CLUSTER_USER@$CLUSTER_IP" "cat /etc/rancher/k3s/k3s.yaml" > "$HIVE_STACK/cluster_kubeconfig/config_host"; then
    # Check if the downloaded file is not empty
    if [[ -s "$HIVE_STACK/cluster_kubeconfig/config_host" ]]; then
        kubeconfig_ok=1
        info "Kubeconfig successfully downloaded from port $p."
        break
    else
        warn "  Kubeconfig file downloaded from port $p is empty."
        rm -f "$HIVE_STACK/cluster_kubeconfig/config_host"
    fi
  else
    warn "  Connection for kubeconfig download on port $p failed."
  fi
done

if [[ $kubeconfig_ok -ne 1 ]]; then
  die " Could not download kubeconfig from any port."
fi

# If script runs interactively (not in CI/CD),
# adjust Kubeconfig to use local SSH tunnel.
if [[ -t 1 ]]; then
  info "Adjusting /etc/hosts and Kubeconfig for 'host.docker.internal'..."
  # Add host.docker.internal to /etc/hosts if not present
  if ! grep -q "host.docker.internal" /etc/hosts; then
    echo "127.0.0.1 host.docker.internal" | sudo tee -a /etc/hosts >/dev/null
  fi

  info "Interactive execution detected. Adjusting Kubeconfig for local SSH tunnel..."
  sed -i -E "s|(server: https://)[^:]+(:6443)|\1host.docker.internal\2|" "$HIVE_STACK/cluster_kubeconfig/config_host"
fi

# Clean up temporary script
rm -f "$TMP_SCRIPT"

NODE_PORT=30000

# ------------------- rl-agent Deployment (now for all modes) -------------------
info "Deploying rl-agent on Hive (local)..."
(
  # Set environment variables for the agent
  sudo mkdir -p "$HIVE_STACK/env" "$HIVE_STACK/secrets"
  sudo chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$HIVE_STACK/env" "$HIVE_STACK/secrets"

  # Ensure write permissions for current user BEFORE copying files
  chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$HIVE_STACK/env" "$HIVE_STACK/secrets" 2>/dev/null || true

  # Copy SSH key for sensor access
  SSH_KEY_TO_USE="${ADLAH_SSH_KEY:-$HOME/.ssh/id_rsa}"
  if [[ -f "$SSH_KEY_TO_USE" ]]; then
    # Delete old file if it is root-owned from previous sudo runs
    rm -f "$HIVE_STACK/secrets/id_rsa" 2>/dev/null || sudo rm -f "$HIVE_STACK/secrets/id_rsa" || true
    cp "$SSH_KEY_TO_USE" "$HIVE_STACK/secrets/id_rsa"
    chmod 600 "$HIVE_STACK/secrets/id_rsa"
  else
    warn "SSH key $SSH_KEY_TO_USE not found. Sensor redirection will fail."
  fi

  cat > "$HIVE_STACK/env/rl-agent.env" <<EOF
ES_HOST=http://elasticsearch:9200
LOG_SOURCE=es
ES_LOG_INDEX=madcat-*
HONEYPOD_NS=honeypod
HONEYPOD_TTL_SEC=1800
HIVE_IP=$(hostname -I | awk '{print $1}')
# Add cluster-specific variables only in cluster mode
EOF

  if [[ "$MODE" == "CLUSTER" ]]; then
    cat >> "$HIVE_STACK/env/rl-agent.env" <<EOF
CLUSTER_SSH_HOST=$CLUSTER_IP
CLUSTER_SSH_USER=$CLUSTER_USER
K8S_API_SERVER=https://$CLUSTER_IP:6443
K8S_TOKEN_FILE=/secrets/cluster_token
K8S_CA_FILE=/secrets/cluster_ca.crt
EOF
  elif [[ "$MODE" == "SENSOR" ]]; then
    # In sensor mode, no SSH connection is needed,
    # as communication goes via Redis.
    # The REDIS_URL is used directly by the redirector-agent.
    cat >> "$HIVE_STACK/env/rl-agent.env" <<EOF
# Configuration for Redis-based redirection (no SSH needed)
EOF
  fi
  
  # Fix permissions after creating the env file
  chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$HIVE_STACK/env/rl-agent.env" 2>/dev/null || true

  info "Starting Docker Compose → rl-agent..."
  docker compose -f "$HIVE_STACK/docker-compose.yml" up -d rl-agent
)

###############################################################################
# Systemd-User-Tunnels (Grafana & K8s-API)
###############################################################################
mkdir -p "$HOME/.config/systemd/user"
loginctl enable-linger "$(whoami)" &>/dev/null || true

# Stop existing tunnels if present
info "Stopping existing SSH tunnels..."
systemctl --user stop grafana-tunnel.service k8s-api-tunnel.service &>/dev/null || true

# Wait briefly to release ports
sleep 2

# Check again if port 6443 is free
if lsof -i :6443 &>/dev/null; then
  warn "Port 6443 is still occupied after stopping tunnel. Forcing release..."
  fuser -k 6443/tcp &>/dev/null || true
  sleep 2
fi

create_tunnel() { local name=$1 portmap=$2
  cat > "$HOME/.config/systemd/user/$name.service" <<SVC
[Unit]
Description=ADLAH SSH-Tunnel ($name)
After=network-online.target

[Service]
ExecStart=/usr/bin/ssh -g -o BatchMode=yes -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 \
         -N -L ${portmap} -p ${SSH_PORT_CFG} ${SSH_KEY_OPT} ${CLUSTER_USER}@${CLUSTER_IP}
Restart=always
RestartSec=5
StartLimitBurst=3
StartLimitIntervalSec=30

[Install]
WantedBy=default.target
SVC
}

create_tunnel grafana-tunnel "3000:localhost:30000"

# Grafana tunnel remains unchanged
# Expose K8s API via gateway address
create_tunnel k8s-api-tunnel "0.0.0.0:6443:localhost:6443"

systemctl --user daemon-reload
systemctl --user enable --now grafana-tunnel.service k8s-api-tunnel.service

# 1. kubectl installieren (stable channel)
# kubectl is now installed by reinstall.sh

# 2. Set Kubeconfig permanently
echo 'export KUBECONFIG=$HOME/hive/cluster_kubeconfig/config_host' >> ~/.bashrc
source ~/.bashrc

# 3. Quick health check of the API
if kubectl --kubeconfig="$HIVE_STACK/cluster_kubeconfig/config_host" get nodes &>/dev/null; then
  info "K8s API reachable "
else
  warn "  K8s API not reachable – please check firewall/SSH tunnel"
fi

info "Cluster onboarding finished "
info "Grafana lokal: http://localhost:3000"

# After setting KUBECONFIG
info "Waiting for K8s API Tunnel..."
TUNNEL_OK=0
for i in {1..30}; do
  if kubectl --kubeconfig="$HIVE_STACK/cluster_kubeconfig/config_host" get nodes &>/dev/null; then
    info "K8s API tunnel is active "
    TUNNEL_OK=1
    break
  fi
  
  # Check if tunnel service is running
  if ! systemctl --user is-active --quiet k8s-api-tunnel.service; then
    warn "K8s API tunnel service is not active. Attempting restart..."
    systemctl --user restart k8s-api-tunnel.service || true
    sleep 5
  fi
  
  warn "Waiting for K8s API Tunnel... Attempt $i"
  sleep 2
done

if [[ ${TUNNEL_OK:-0} -ne 1 ]]; then
  warn " K8s API Tunnel could not be established after 30 attempts."
  
  # Diagnose-Informationen sammeln
  warn "Tunnel service status:"
  systemctl --user status k8s-api-tunnel.service --no-pager || true
  
  warn "Port 6443 usage:"
  lsof -i :6443 || true
  
  warn "Trying kubectl directly:"
  kubectl --kubeconfig="$HIVE_STACK/cluster_kubeconfig/config_host" get nodes || true
  
  die  "Aborting due to missing K8s API tunnel. Please check SSH configuration."
fi
info "Cleaning up old honeypod deployments & pods (final check after RL agent start)..."

# Keep warm-up pool - DO NOT delete deployment (needed for fast pod adoption)

# Then delete all pods with honeypod label in honeypod namespace
kubectl --kubeconfig="$HIVE_STACK/cluster_kubeconfig/config_host" delete pod -n honeypod -l app=honeypod --ignore-not-found=true --grace-period=0 --force || true

# Wait briefly
sleep 2

# If pods are still in Terminating status, delete them with a patch
info "Removing stubborn Terminating pods..."
for pod in $(kubectl --kubeconfig="$HIVE_STACK/cluster_kubeconfig/config_host" get pods -n honeypod -l app=honeypod -o name 2>/dev/null | cut -d/ -f2); do
  kubectl --kubeconfig="$HIVE_STACK/cluster_kubeconfig/config_host" patch pod "$pod" -n honeypod -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
done

# Optional wait until everything is gone (with shorter timeout)
for i in {1..10}; do
  if ! kubectl --kubeconfig="$HIVE_STACK/cluster_kubeconfig/config_host" get pods -n honeypod -l app=honeypod 2>/dev/null | grep -q honeypod; then
    info "Honeypod pods finally removed."
    break
  fi
  warn "Honeypod pods still present... Waiting ($i)"
  sleep 1
done

# If pods are still there after 10 seconds, it's not a critical error
if kubectl --kubeconfig="$HIVE_STACK/cluster_kubeconfig/config_host" get pods -n honeypod -l app=honeypod 2>/dev/null | grep -q honeypod; then
  warn "Some Honeypod pods are still in Terminating status. This is normal and will resolve itself."
fi

#############################################################################
# 3e) Honeypod Warm-Up Pool (Pre-warmed Pods)
#############################################################################
# This section has been removed to prevent deployment errors.
# The warm-up pool is no longer created.
info "Skipping honeypod warm-up pool creation."

# Make Kubeconfig automatically available
mkdir -p $HOME/.kube
cp -f "$HIVE_STACK/cluster_kubeconfig/config_host" $HOME/.kube/config
# Alternativ (Symlink):
# ln -sf "$HIVE_STACK/cluster_kubeconfig/config_host" $HOME/.kube/config

info "Kubeconfig copied to ~/.kube/config. kubectl can now be used without path specification."
