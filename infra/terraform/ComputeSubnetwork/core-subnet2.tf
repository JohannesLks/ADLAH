resource "google_compute_subnetwork" "core_subnet2" {
  ip_cidr_range              = var.core_subnet2_cidr
  name                       = "core-subnet2-${var.env}"
  network                    = var.core_vpc_self_link
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = var.project_id
  purpose                    = "PRIVATE"
  region                     = var.region
  stack_type                 = "IPV4_ONLY"
}
# terraform import google_compute_subnetwork.core_subnet2 projects/${var.project_id}/regions/${var.region}/subnetworks/core-subnet2
