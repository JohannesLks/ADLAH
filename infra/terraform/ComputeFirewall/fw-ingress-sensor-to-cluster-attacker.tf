resource "google_compute_firewall" "fw_ingress_sensor_to_cluster_attacker" {
  allow {
    ports    = ["2222"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  name          = "fw-ingress-sensor-to-cluster-attacker"
  network       = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
  priority      = 1000
  project       = "adlah3"
  source_ranges = ["10.1.0.5"]
  target_tags   = ["cluster"]
}
# terraform import google_compute_firewall.fw_ingress_sensor_to_cluster_attacker projects/adlah3/global/firewalls/fw-ingress-sensor-to-cluster-attacker
