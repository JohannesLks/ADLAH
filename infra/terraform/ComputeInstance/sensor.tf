resource "google_compute_instance" "sensor" {
  name         = "sensor-${var.env}"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.sensor_machine_type

  boot_disk {
    auto_delete = true
    device_name = "sensor"
    initialize_params {
      image = var.ubuntu_image_self_link
      size  = var.sensor_disk_size_gb
      type  = "pd-balanced"
    }
    mode = "READ_WRITE"
  }

  confidential_instance_config { enable_confidential_compute = false }
  labels   = { env = var.env }
  metadata = { enable-osconfig = "TRUE" }

  network_interface {
    access_config { network_tier = "PREMIUM" }
    network    = var.core_vpc_self_link
    subnetwork = var.core_subnet2_self_link
    stack_type = "IPV4_ONLY"
    network_ip = var.sensor_core_ip == "" ? null : var.sensor_core_ip
  }

  network_interface {
    access_config { network_tier = "PREMIUM" }
    network    = var.honeynet_vpc_self_link
    subnetwork = var.dmz_subnet_self_link
    stack_type = "IPV4_ONLY"
    network_ip = var.sensor_dmz_ip == "" ? null : var.sensor_dmz_ip
  }


}
# terraform import google_compute_instance.sensor projects/${var.project_id}/zones/${var.zone}/instances/sensor
