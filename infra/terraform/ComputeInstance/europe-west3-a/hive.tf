resource "google_compute_instance" "hive" {
  name         = "hive-${var.env}"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.hive_machine_type

  boot_disk {
    auto_delete = true
    device_name = "hive"
    initialize_params {
      image = data.google_compute_image.ubuntu_base.self_link
      size  = var.hive_disk_size_gb
      type  = "pd-balanced"
    }
    mode = "READ_WRITE"
  }

  confidential_instance_config { enable_confidential_compute = false }

  labels = { env = var.env }

  metadata = {
    enable-osconfig    = "TRUE"
    serial-port-enable = "true"
    # NOTE: SSH keys should be managed via OS Login or metadata variables; stripped static keys.
  }

  network_interface {
    access_config {
      nat_ip       = coalesce(try(google_compute_address.hive_fixed[0].address, null), google_compute_address.hive_external.address)
      network_tier = "PREMIUM"
    }
    network    = google_compute_network.core_vpc.self_link
    subnetwork = google_compute_subnetwork.core_subnet2.self_link
    stack_type = "IPV4_ONLY"
    network_ip = var.hive_internal_ip == "" ? null : var.hive_internal_ip
  }

  scheduling { automatic_restart = true on_host_maintenance = "MIGRATE" provisioning_model = "STANDARD" }

  service_account {
    email  = local.compute_service_account_email
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }

  shielded_instance_config { enable_integrity_monitoring = true enable_vtpm = true }

  tags = ["hive", "iap", "iap-enabled", var.env]
}
# terraform import google_compute_instance.hive projects/${var.project_id}/zones/${var.zone}/instances/hive
