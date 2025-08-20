resource "google_compute_subnetwork" "cluster_subnet" {
  ip_cidr_range              = var.cluster_subnet_cidr
  name                       = "cluster-subnet-${var.env}"
  network                    = google_compute_network.cluster_vpc.self_link
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = var.project_id
  purpose                    = "PRIVATE"
  region                     = var.region
  stack_type                 = "IPV4_ONLY"
}
# terraform import google_compute_subnetwork.cluster_subnet projects/${var.project_id}/regions/${var.region}/subnetworks/cluster-subnet
