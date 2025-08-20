resource "google_compute_route" "peering_route_e33406c86a0ca3e5" {
  description = "Auto generated route via peering [coreanddmz]."
  dest_range  = "10.0.0.0/24"
  name        = "peering-route-e33406c86a0ca3e5"
  network     = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/core-vpc"
  priority    = 0
  project     = "adlah3"
}
# terraform import google_compute_route.peering_route_e33406c86a0ca3e5 projects/adlah3/global/routes/peering-route-e33406c86a0ca3e5
