resource "google_compute_instance" "cluster" {
  name         = "cluster-${var.env}"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.cluster_machine_type

  boot_disk {
    auto_delete = true
    device_name = "cluster"
    initialize_params {
      image = data.google_compute_image.ubuntu_base.self_link
      size  = var.cluster_disk_size_gb
      type  = "pd-balanced"
    }
    mode = "READ_WRITE"
  }

  confidential_instance_config { enable_confidential_compute = false }
  labels = { env = var.env }
  metadata = { enable-osconfig = "TRUE" }

  network_interface {
    access_config { network_tier = "PREMIUM" }
    network    = google_compute_network.core_vpc.self_link
    subnetwork = google_compute_subnetwork.core_subnet2.self_link
    stack_type = "IPV4_ONLY"
    network_ip = var.cluster_core_ip == "" ? null : var.cluster_core_ip
  }

  network_interface {
    access_config { network_tier = "PREMIUM" }
    network    = google_compute_network.cluster_vpc.self_link
    subnetwork = google_compute_subnetwork.cluster_subnet.self_link
    stack_type = "IPV4_ONLY"
    network_ip = var.cluster_cluster_ip == "" ? null : var.cluster_cluster_ip
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
  tags = ["cluster", var.env]
}
# terraform import google_compute_instance.cluster projects/${var.project_id}/zones/${var.zone}/instances/cluster
resource "google_compute_instance" "cluster" {
  name         = "cluster-${var.env}"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.cluster_machine_type

  boot_disk {
    auto_delete = true
    device_name = "cluster"
    initialize_params {
      image = data.google_compute_image.ubuntu_base.self_link
      size  = var.cluster_disk_size_gb
      type  = "pd-balanced"
    }
    mode = "READ_WRITE"
  }

  confidential_instance_config { enable_confidential_compute = false }
  labels = { env = var.env }
  metadata = { enable-osconfig = "TRUE" }

  network_interface {
    access_config { network_tier = "PREMIUM" }
    network    = google_compute_network.core_vpc.self_link
    subnetwork = google_compute_subnetwork.core_subnet2.self_link
    stack_type = "IPV4_ONLY"
    network_ip = var.cluster_core_ip == "" ? null : var.cluster_core_ip
  }

  network_interface {
    access_config { network_tier = "PREMIUM" }
    network    = google_compute_network.cluster_vpc.self_link
    subnetwork = google_compute_subnetwork.cluster_subnet.self_link
    stack_type = "IPV4_ONLY"
    network_ip = var.cluster_cluster_ip == "" ? null : var.cluster_cluster_ip
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
  tags = ["cluster", var.env]
}
# terraform import google_compute_instance.cluster projects/${var.project_id}/zones/${var.zone}/instances/cluster
