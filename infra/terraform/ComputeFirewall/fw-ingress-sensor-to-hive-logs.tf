resource "google_compute_firewall" "fw_ingress_sensor_to_hive_logs" {
  allow {
    protocol = "tcp"
    ports    = ["5044", "15044"]
  }
  direction     = "INGRESS"
  name          = "sensor-to-hive-logs-${var.env}"
  network       = var.core_vpc_self_link
  priority      = 1000
  project       = var.project_id
  source_ranges = [var.sensor_core_ip]
  target_tags   = ["hive", var.env]
}
# terraform import google_compute_firewall.fw_ingress_sensor_to_hive_logs projects/${var.project_id}/global/firewalls/sensor-to-hive-logs-${var.env}
