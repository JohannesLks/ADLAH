resource "google_compute_network" "cluster_vpc" {
  auto_create_subnetworks                   = false
  mtu                                       = 1460
  name                                      = "cluster-vpc-${var.env}"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = var.project_id
  routing_mode                              = "REGIONAL"
}
# terraform import google_compute_network.cluster_vpc projects/${var.project_id}/global/networks/cluster-vpc
