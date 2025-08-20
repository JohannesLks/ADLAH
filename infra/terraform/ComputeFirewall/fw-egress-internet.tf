resource "google_compute_firewall" "fw_egress_internet" {
  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  direction          = "EGRESS"
  name               = "fw-egress-internet"
  network            = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
  priority           = 1000
  project            = "adlah3"
}
# terraform import google_compute_firewall.fw_egress_internet projects/adlah3/global/firewalls/fw-egress-internet
