resource "google_compute_route" "peering_route_3065c61081c11abc" {
  description = "Auto generated route via peering [dmzandcore]."
  dest_range  = "10.1.0.0/24"
  name        = "peering-route-3065c61081c11abc"
  network     = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/honeynet-vpc"
  priority    = 0
  project     = "adlah3"
}
# terraform import google_compute_route.peering_route_3065c61081c11abc projects/adlah3/global/routes/peering-route-3065c61081c11abc
