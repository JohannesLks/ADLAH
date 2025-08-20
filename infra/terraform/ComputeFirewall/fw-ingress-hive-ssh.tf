resource "google_compute_firewall" "fw_ingress_hive_ssh" {
  allow { protocol = "tcp" ports = ["22"] }
  direction     = "INGRESS"
  name          = "hive-ssh-open-${var.env}"
  network       = google_compute_network.core_vpc.self_link
  priority      = 1000
  project       = var.project_id
  source_ranges = [var.internet_cidr] # consider restricting in production
  target_tags   = ["hive", var.env]
}
# terraform import google_compute_firewall.fw_ingress_hive_ssh projects/${var.project_id}/global/firewalls/hive-ssh-open-${var.env}
