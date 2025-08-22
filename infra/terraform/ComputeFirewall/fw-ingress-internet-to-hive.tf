resource "google_compute_firewall" "fw_ingress_internet_to_hive" {
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  direction     = "INGRESS"
  name          = "internet-to-hive-${var.env}"
  network       = var.core_vpc_self_link
  priority      = 100
  project       = var.project_id
  source_ranges = [var.internet_cidr]
  target_tags   = ["hive", var.env]
}
# terraform import google_compute_firewall.fw_ingress_internet_to_hive projects/${var.project_id}/global/firewalls/internet-to-hive-${var.env}
