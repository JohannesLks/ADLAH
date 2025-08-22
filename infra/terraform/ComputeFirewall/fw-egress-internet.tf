resource "google_compute_firewall" "fw_egress_internet" {
  allow {
    protocol = "all"
  }
  destination_ranges = [var.internet_cidr]
  direction          = "EGRESS"
  name               = "egress-internet-${var.env}"
  network            = var.core_vpc_self_link
  priority           = 1000
  project            = var.project_id
}
# terraform import google_compute_firewall.fw_egress_internet projects/${var.project_id}/global/firewalls/egress-internet-${var.env}
