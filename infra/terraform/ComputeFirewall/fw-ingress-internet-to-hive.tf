resource "google_compute_firewall" "fw_ingress_internet_to_hive" {
  allow {
    ports    = ["80", "443"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  name          = "fw-ingress-internet-to-hive"
  network       = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
  priority      = 100
  project       = "adlah3"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["hive"]
}
# terraform import google_compute_firewall.fw_ingress_internet_to_hive projects/adlah3/global/firewalls/fw-ingress-internet-to-hive
