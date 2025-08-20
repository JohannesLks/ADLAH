resource "google_compute_firewall" "fw_ingress_allow_all_sensor" {
  allow {
    protocol = "all"
  }

  direction     = "INGRESS"
  name          = "fw-ingress-allow-all-sensor"
  network       = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/honeynet-vpc"
  priority      = 1000
  project       = "adlah3"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["sensor"]
}
# terraform import google_compute_firewall.fw_ingress_allow_all_sensor projects/adlah3/global/firewalls/fw-ingress-allow-all-sensor
