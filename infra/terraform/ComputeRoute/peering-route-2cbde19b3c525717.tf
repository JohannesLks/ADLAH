resource "google_compute_route" "peering_route_2cbde19b3c525717" {
  description = "Auto generated route via peering [dmzandcore]."
  dest_range  = "10.10.1.0/24"
  name        = "peering-route-2cbde19b3c525717"
  network     = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/honeynet-vpc"
  priority    = 0
  project     = "adlah3"
}
# terraform import google_compute_route.peering_route_2cbde19b3c525717 projects/adlah3/global/routes/peering-route-2cbde19b3c525717
