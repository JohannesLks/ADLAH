resource "google_compute_firewall" "fw_ingress_hive_to_cluster_ssh" {
  allow { protocol = "tcp" ports = ["22"] }
  direction     = "INGRESS"
  name          = "hive-to-cluster-ssh-${var.env}"
  network       = google_compute_network.core_vpc.self_link
  priority      = 1000
  project       = var.project_id
  source_ranges = [var.hive_internal_ip]
  target_tags   = ["cluster", var.env]
}
# terraform import google_compute_firewall.fw_ingress_hive_to_cluster_ssh projects/${var.project_id}/global/firewalls/hive-to-cluster-ssh-${var.env}
