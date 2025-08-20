resource "google_compute_firewall" "fw_ingress_sensor_to_cluster_attacker" {
  allow { protocol = "tcp" ports = ["2222"] }
  direction     = "INGRESS"
  name          = "sensor-to-cluster-attacker-${var.env}"
  network       = google_compute_network.core_vpc.self_link
  priority      = 1000
  project       = var.project_id
  source_ranges = [var.sensor_core_ip]
  target_tags   = ["cluster", var.env]
}
# terraform import google_compute_firewall.fw_ingress_sensor_to_cluster_attacker projects/${var.project_id}/global/firewalls/sensor-to-cluster-attacker-${var.env}
