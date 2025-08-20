resource "google_compute_subnetwork" "dmz_subnet" {
  ip_cidr_range              = "10.0.0.0/24"
  name                       = "dmz-subnet"
  network                    = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/honeynet-vpc"
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = "adlah3"
  purpose                    = "PRIVATE"
  region                     = "europe-west3"
  stack_type                 = "IPV4_ONLY"
}
# terraform import google_compute_subnetwork.dmz_subnet projects/adlah3/regions/europe-west3/subnetworks/dmz-subnet
