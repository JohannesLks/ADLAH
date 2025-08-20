resource "google_compute_firewall" "fw_ingress_sensor_to_hive_logs" {
  allow {
    ports    = ["5044", "15044"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  name          = "fw-ingress-sensor-to-hive-logs"
  network       = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
  priority      = 1000
  project       = "adlah3"
  source_ranges = ["10.1.0.5"]
  target_tags   = ["hive"]
}
# terraform import google_compute_firewall.fw_ingress_sensor_to_hive_logs projects/adlah3/global/firewalls/fw-ingress-sensor-to-hive-logs
