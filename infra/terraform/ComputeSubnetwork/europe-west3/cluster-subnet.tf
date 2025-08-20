resource "google_compute_subnetwork" "cluster_subnet" {
  ip_cidr_range              = "10.2.0.0/16"
  name                       = "cluster-subnet"
  network                    = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/cluster-vpc"
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = "adlah3"
  purpose                    = "PRIVATE"
  region                     = "europe-west3"
  stack_type                 = "IPV4_ONLY"
}
# terraform import google_compute_subnetwork.cluster_subnet projects/adlah3/regions/europe-west3/subnetworks/cluster-subnet
