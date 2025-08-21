resource "google_compute_firewall" "default_allow_ssh" {
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  direction     = "INGRESS"
  name          = "default-allow-ssh-${var.env}"
  network       = "default" # leaving default network ref static; consider removal if unused
  priority      = 65534
  project       = var.project_id
  source_ranges = [var.internet_cidr]
}
# terraform import google_compute_firewall.default_allow_ssh projects/${var.project_id}/global/firewalls/default-allow-ssh
