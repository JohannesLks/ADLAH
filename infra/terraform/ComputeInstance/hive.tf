resource "google_compute_instance" "hive" {
  name         = "hive-${var.env}"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.hive_machine_type

 tags = ["hive"]

  boot_disk {
    auto_delete = true
    device_name = "hive"
    initialize_params {
      image = var.ubuntu_image_self_link
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
      nat_ip       = coalesce(try(var.hive_fixed_address, null), var.hive_external_address)
      network_tier = "PREMIUM"
    }
    network    = var.core_vpc_self_link
    subnetwork = var.core_subnet2_self_link
    stack_type = "IPV4_ONLY"
    network_ip = var.hive_internal_ip == "" ? null : var.hive_internal_ip
  }


}
# terraform import google_compute_instance.hive projects/${var.project_id}/zones/${var.zone}/instances/hive
