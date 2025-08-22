resource "google_compute_firewall" "fw_ingress_bastion_to_hive_ssh" {
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  direction     = "INGRESS"
  name          = "bastion-to-hive-ssh-${var.env}"
  network       = var.core_vpc_self_link
  priority      = 1000
  project       = var.project_id
  source_ranges = [var.bastion_internal_ip]
  target_tags   = ["hive", var.env]
}
# terraform import google_compute_firewall.fw_ingress_bastion_to_hive_ssh projects/${var.project_id}/global/firewalls/bastion-to-hive-ssh-${var.env}
