resource "google_compute_network" "core_vpc" {
  auto_create_subnetworks                   = false
  mtu                                       = 1460
  name                                      = "core-vpc"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = "adlah3"
  routing_mode                              = "REGIONAL"
}
# terraform import google_compute_network.core_vpc projects/adlah3/global/networks/core-vpc
