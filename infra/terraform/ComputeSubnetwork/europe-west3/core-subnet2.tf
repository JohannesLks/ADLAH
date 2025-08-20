resource "google_compute_subnetwork" "core_subnet2" {
  ip_cidr_range              = "10.1.0.0/24"
  name                       = "core-subnet2"
  network                    = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = "adlah3"
  purpose                    = "PRIVATE"
  region                     = "europe-west3"
  stack_type                 = "IPV4_ONLY"
}
# terraform import google_compute_subnetwork.core_subnet2 projects/adlah3/regions/europe-west3/subnetworks/core-subnet2
