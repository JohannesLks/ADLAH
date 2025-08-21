resource "google_compute_firewall" "fw_ingress_hive_to_sensor" {
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  direction     = "INGRESS"
  name          = "hive-to-sensor-ssh-${var.env}"
  network       = var.core_vpc_self_link
  priority      = 1000
  project       = var.project_id
  source_ranges = [var.hive_internal_ip]
  target_tags   = ["sensor", var.env]
}
# terraform import google_compute_firewall.fw_ingress_hive_to_sensor projects/${var.project_id}/global/firewalls/hive-to-sensor-ssh-${var.env}
