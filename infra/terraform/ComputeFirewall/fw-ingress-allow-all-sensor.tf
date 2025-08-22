resource "google_compute_firewall" "fw_ingress_allow_all_sensor" {
  allow {
    protocol = "all"
  }
  direction     = "INGRESS"
  name          = "allow-all-sensor-${var.env}"
  network       = var.honeynet_vpc_self_link
  priority      = 1000
  project       = var.project_id
  source_ranges = [var.internet_cidr]
  target_tags   = ["sensor", var.env]
}
# terraform import google_compute_firewall.fw_ingress_allow_all_sensor projects/${var.project_id}/global/firewalls/allow-all-sensor-${var.env}
