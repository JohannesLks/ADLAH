resource "google_compute_firewall" "fw_ingress_bastion_to_internet_ssh" {
  allow { protocol = "tcp" ports = ["22"] }
  direction     = "INGRESS"
  name          = "internet-to-bastion-ssh-${var.env}"
  network       = google_compute_network.honeynet_vpc.self_link
  priority      = 1000
  project       = var.project_id
  source_ranges = [var.internet_cidr]
  target_tags   = ["bastion", var.env]
}
# terraform import google_compute_firewall.fw_ingress_bastion_to_internet_ssh projects/${var.project_id}/global/firewalls/internet-to-bastion-ssh-${var.env}
