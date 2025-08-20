resource "google_compute_firewall" "allow_iap_ssh" {
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  name          = "allow-iap-ssh"
  network       = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
  priority      = 1000
  project       = "adlah3"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-enabled"]
}
# terraform import google_compute_firewall.allow_iap_ssh projects/adlah3/global/firewalls/allow-iap-ssh
