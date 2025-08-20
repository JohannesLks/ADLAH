resource "google_compute_instance" "hive" {
  boot_disk {
    auto_delete = true
    device_name = "hive"

    initialize_params {
      image = "https://www.googleapis.com/compute/beta/projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2204-jammy-v20250723"
      size  = 100
      type  = "pd-balanced"
    }

    mode   = "READ_WRITE"
    source = "https://www.googleapis.com/compute/v1/projects/adlah3/zones/europe-west3-a/disks/hive"
  }

  confidential_instance_config {
    enable_confidential_compute = false
  }

  labels = {
    goog-ops-agent-policy = "v2-x86-template-1-4-0"
    managed-by-cnrm       = "true"
  }

  machine_type = "e2-standard-2"

  metadata = {
    enable-osconfig    = "TRUE"
    serial-port-enable = "true"
    ssh-keys           = "lukasjohannesmoeller00:ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ56PVJI/Lk48T2zeaRr5mqr/yMfCQXM2vRHP85UOTKa5zv5UFICLSqdbbWAxktndxAP/XMQOy04Q9PuXjOQSro= google-ssh {\"userName\":\"lukasjohannesmoeller00@gmail.com\",\"expireOn\":\"2025-08-08T20:48:37+0000\"}\nlukasjohannesmoeller00:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDO3TNzvIcXsKYUN+N4+L64YzBnLhVtYUNFnHFavduRAZ2irJHUxyVjFLfl0PrJW5e91cXoZZq06gIH8IkIOcRW3XxBlpRVR93CZTNIOOOnNmkaFUXFrw62t40Gu2Kl/muLaxhC90oQFzfHogMDgZ7MketNb0PbV60OEtaxzfAQ3nW7y8uj3ksywGULFPkOgTddVlXP0CiiSt28wbzBLpssLL6ksXVFbBXeUno5N+F3DdUV2NYg/AYp6Emmugmeplmk9Ae16xqU6hJrQMrGqJk9vZW4MDvyaaOfL7q7JG1QRvW8RYoPXrBohX5J3c38cBxbwf3G6aYdcFFwMHpF4M7D google-ssh {\"userName\":\"lukasjohannesmoeller00@gmail.com\",\"expireOn\":\"2025-08-08T20:48:41+0000\"}\nlukasjohannesmoeller00:ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHqoy6pWkya5Ypsg2uRnpIWeibwU2OLeqMd21q0tN0LnYzpbAzHO2kGh06Tlt6+Gurfz9fIEA9iSBPMssaGmPO8= google-ssh {\"userName\":\"lukasjohannesmoeller00@gmail.com\",\"expireOn\":\"2025-08-08T20:49:08+0000\"}\nlukasjohannesmoeller00:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAHjSaKggp6O/rN0QovwTfXBlZopklBzRYcONfX+ygDW/Wdz0SRRc63aEyLJUlaAEdneOwcCLayrWOlTAtueJgM7E9GfcaP0YVGfWvWX+MDOBGlJdlWEWS0eDX9bba+3o4fnRtc6AQVSmJmZgajfCUY1jy4Ljz+xN7wRWucREWaM/vU4MA/JP0JUxjiR+PaOqoBF571iRFAejh5fHhK2bot69YDmva6FpX+LfYOh5bNfJ5yjmnTfXfBAsKfAlCgE8hnZAlXmEiFoFVHmsp6XFeaVsDqR2WUxACdAVAC+tphuQIc9H3rM1wbLugerU/Q940cRl3X0kCDjrwTR4Ww2oqrU= google-ssh {\"userName\":\"lukasjohannesmoeller00@gmail.com\",\"expireOn\":\"2025-08-08T20:49:12+0000\"}"
    startup-script     = "#!/usr/bin/env bash\n# GCE startup-script: repair and (re)enable OpenSSH\n# Works on Debian/Ubuntu GCE images\n\nset -euo pipefail\n\nlog() { echo \"[$(date -Is)] $*\"; logger -t gce-startup-ssh \"$*\"; }\n\n# 0) Ensure openssh-server is installed\nif ! dpkg -s openssh-server >/dev/null 2>&1; then\n  log \"openssh-server not found, installing…\"\n  apt-get update -y && apt-get install -y --no-install-recommends openssh-server\nfi\n\nCFG=\"/etc/ssh/sshd_config\"\nBAK=\"/etc/ssh/sshd_config.bak.gce.$(date +%F-%H%M%S)\"\n\n# 1) Validate existing config; if broken or contains garbage, replace with sane minimal config\nneed_fix=0\nif ! sshd -t -f \"$CFG\" >/dev/null 2>&1; then\n  need_fix=1\nelse\n  # crude corruption heuristics\n  if grep -Eq '^(Reading|Unpacking|Selecting|Preparing|Get:|Fetched|apache2-utils|Processing)\\b' \"$CFG\"; then\n    need_fix=1\n  fi\nfi\n\nif [[ \"$need_fix\" -eq 1 ]]; then\n  log \"Detected broken sshd_config; backing up to $BAK and writing minimal config.\"\n  cp -a \"$CFG\" \"$BAK\" || true\n  cat > \"$CFG\" <<'EOF'\n# Minimal, secure, GCE-friendly sshd_config\nPort 22\nProtocol 2\nAddressFamily any\nListenAddress 0.0.0.0\n\n# Auth (adjust if you temporarily need password login)\nPasswordAuthentication no\nKbdInteractiveAuthentication no\nChallengeResponseAuthentication no\nUsePAM yes\nPermitRootLogin prohibit-password\nPubkeyAuthentication yes\nAuthorizedKeysFile .ssh/authorized_keys\n\n# Hardening & defaults\nLoginGraceTime 30\nX11Forwarding no\nPrintMotd no\nAcceptEnv LANG LC_*\nSubsystem sftp /usr/lib/openssh/sftp-server\nEOF\nfi\n\n# 2) Make sure the file has correct perms\nchown root:root \"$CFG\"\nchmod 600 \"$CFG\"\n\n# 3) Validate final config\nif ! sshd -t -f \"$CFG\" >/dev/null; then\n  log \"FATAL: sshd_config still invalid after repair.\"\n  exit 1\nfi\n\n\n# 5) Enable & restart sshd\nlog \"Enabling and restarting sshd…\"\nsystemctl enable ssh || true\nsystemctl restart ssh\n\n# 6) Show listening socket (to serial log)\nif command -v ss >/dev/null 2>&1; then\n  ss -lntp | grep ':22' || true\nelse\n  netstat -lntp | grep ':22' || true\nfi\n\nlog \"startup-script completed.\"\n"
  }

  name = "hive"

  network_interface {
    access_config {
      nat_ip       = "34.40.80.159"
      network_tier = "PREMIUM"
    }

    network            = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
    network_ip         = "10.1.0.10"
    stack_type         = "IPV4_ONLY"
    subnetwork         = "https://www.googleapis.com/compute/v1/projects/adlah3/regions/europe-west3/subnetworks/core-subnet2"
    subnetwork_project = "adlah3"
  }

  project = "adlah3"

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "630035832230-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_vtpm                 = true
  }

  tags = ["hive", "iap", "iap-enabled"]
  zone = "europe-west3-a"
}
# terraform import google_compute_instance.hive projects/adlah3/zones/europe-west3-a/instances/hive
