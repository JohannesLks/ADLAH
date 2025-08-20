resource "google_compute_instance" "bastion" {
  name         = "bastion-${var.env}"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.bastion_machine_type

  boot_disk {
    auto_delete = true
    device_name = "bastion"
    initialize_params {
      image = data.google_compute_image.ubuntu_base.self_link
      size  = var.bastion_disk_size_gb
      type  = "pd-balanced"
    }
    mode = "READ_WRITE"
  }

  confidential_instance_config { enable_confidential_compute = false }

  labels = { env = var.env }

  metadata = { enable-osconfig = "TRUE" }

  network_interface {
    access_config {
      nat_ip       = coalesce(try(google_compute_address.bastion_fixed[0].address, null), google_compute_address.bastion.address)
      network_tier = "PREMIUM"
    }
    network    = google_compute_network.honeynet_vpc.self_link
    subnetwork = google_compute_subnetwork.dmz_subnet.self_link
    stack_type = "IPV4_ONLY"
    dynamic "network_ip" {
      for_each = var.bastion_internal_ip == "" ? [] : [var.bastion_internal_ip]
      content { # dummy block, we cannot set network_ip this way; fallback below }
    }
    # direct attribute for internal IP if provided
    network_ip = var.bastion_internal_ip == "" ? null : var.bastion_internal_ip
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

  tags = ["bastion", var.env]
}
# terraform import google_compute_instance.bastion projects/${var.project_id}/zones/${var.zone}/instances/bastion
