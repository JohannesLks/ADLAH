resource "google_compute_subnetwork" "dmz_subnet" {
  ip_cidr_range              = var.dmz_cidr
  name                       = "dmz-subnet-${var.env}"
  network                    = google_compute_network.honeynet_vpc.self_link
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS" # consider enabling if needed
  project                    = var.project_id
  purpose                    = "PRIVATE"
  region                     = var.region
  stack_type                 = "IPV4_ONLY"
}
# terraform import google_compute_subnetwork.dmz_subnet projects/${var.project_id}/regions/${var.region}/subnetworks/dmz-subnet
