resource "google_compute_network" "core_vpc" {
  auto_create_subnetworks                   = false
  mtu                                       = 1460
  name                                      = "core-vpc-${var.env}"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = var.project_id
  routing_mode                              = "REGIONAL"
}
# terraform import google_compute_network.core_vpc projects/${var.project_id}/global/networks/core-vpc
