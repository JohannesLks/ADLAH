resource "google_compute_instance" "cluster" {
  name         = "cluster-${var.env}"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.cluster_machine_type

  boot_disk {
    auto_delete = true
    device_name = "cluster"
    initialize_params {
      image = var.ubuntu_image_self_link
      size  = var.cluster_disk_size_gb
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
    network_ip = var.cluster_core_ip == "" ? null : var.cluster_core_ip
  }

  network_interface {
    access_config { network_tier = "PREMIUM" }
    network    = var.cluster_vpc_self_link
    subnetwork = var.cluster_subnet_self_link
    stack_type = "IPV4_ONLY"
    network_ip = var.cluster_cluster_ip == "" ? null : var.cluster_cluster_ip
  }


}
# terraform import google_compute_instance.cluster projects/${var.project_id}/zones/${var.zone}/instances/cluster
