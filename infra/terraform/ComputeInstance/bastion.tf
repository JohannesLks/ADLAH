resource "google_compute_instance" "bastion" {
  name         = "bastion-${var.env}"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.bastion_machine_type

  tags = ["bastion"]

  boot_disk {
    auto_delete = true
    device_name = "bastion"
    initialize_params {
      image = var.ubuntu_image_self_link
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
      nat_ip       = coalesce(try(var.bastion_fixed_address, null), var.bastion_address)
      network_tier = "PREMIUM"
    }
    network    = var.honeynet_vpc_self_link
    subnetwork = var.dmz_subnet_self_link
    stack_type = "IPV4_ONLY"
      # direct attribute for internal IP if provided
      network_ip = var.bastion_internal_ip == "" ? null : var.bastion_internal_ip
    }
  # terraform import google_compute_instance.bastion projects/${var.project_id}/zones/${var.zone}/instances/bastion

}
