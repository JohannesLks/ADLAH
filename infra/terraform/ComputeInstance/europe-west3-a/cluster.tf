resource "google_compute_instance" "cluster" {
  boot_disk {
    auto_delete = true
    device_name = "cluster"

    initialize_params {
      image = "https://www.googleapis.com/compute/beta/projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2204-jammy-v20250723"
      size  = 50
      type  = "pd-balanced"
    }

    mode   = "READ_WRITE"
    source = "https://www.googleapis.com/compute/v1/projects/adlah3/zones/europe-west3-a/disks/cluster"
  }

  confidential_instance_config {
    enable_confidential_compute = false
  }

  labels = {
    goog-ops-agent-policy = "v2-x86-template-1-4-0"
    managed-by-cnrm       = "true"
  }

  machine_type = "e2-custom-4-11008"

  metadata = {
    enable-osconfig = "TRUE"
  }

  name = "cluster"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    network            = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
    network_ip         = "10.1.0.15"
    stack_type         = "IPV4_ONLY"
    subnetwork         = "https://www.googleapis.com/compute/v1/projects/adlah3/regions/europe-west3/subnetworks/core-subnet2"
    subnetwork_project = "adlah3"
  }

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    network            = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/cluster-vpc"
    network_ip         = "10.2.0.15"
    stack_type         = "IPV4_ONLY"
    subnetwork         = "https://www.googleapis.com/compute/v1/projects/adlah3/regions/europe-west3/subnetworks/cluster-subnet"
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

  tags = ["cluster"]
  zone = "europe-west3-a"
}
# terraform import google_compute_instance.cluster projects/adlah3/zones/europe-west3-a/instances/cluster
