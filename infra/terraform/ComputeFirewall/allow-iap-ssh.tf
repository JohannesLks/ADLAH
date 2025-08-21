resource "google_compute_firewall" "allow_iap_ssh" {
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  direction     = "INGRESS"
  name          = "allow-iap-ssh-${var.env}"
  network       = var.core_vpc_self_link
  priority      = 1000
  project       = var.project_id
  source_ranges = var.iap_source_range
  target_tags   = ["iap-enabled", var.env]
}
# terraform import google_compute_firewall.allow_iap_ssh projects/${var.project_id}/global/firewalls/allow-iap-ssh
