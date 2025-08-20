resource "google_compute_firewall" "fw_ingress_bastion_to_hive_ssh" {
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  name          = "fw-ingress-bastion-to-hive-ssh"
  network       = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
  priority      = 1000
  project       = "adlah3"
  source_ranges = ["10.0.0.21"]
  target_tags   = ["hive"]
}
# terraform import google_compute_firewall.fw_ingress_bastion_to_hive_ssh projects/adlah3/global/firewalls/fw-ingress-bastion-to-hive-ssh
