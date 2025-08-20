resource "google_compute_firewall" "fw_ingress_hive_to_cluster_ssh" {
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  name          = "fw-ingress-hive-to-cluster-ssh"
  network       = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
  priority      = 1000
  project       = "adlah3"
  source_ranges = ["10.1.0.10"]
  target_tags   = ["cluster"]
}
# terraform import google_compute_firewall.fw_ingress_hive_to_cluster_ssh projects/adlah3/global/firewalls/fw-ingress-hive-to-cluster-ssh
