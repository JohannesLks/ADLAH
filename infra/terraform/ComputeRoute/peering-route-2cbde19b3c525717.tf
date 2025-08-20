resource "google_compute_route" "dmz_to_core_cidr1" {
  description = "Route dmz -> core subnet1"
  dest_range  = var.core_subnet_cidr
  name        = "dmz-to-core1-${var.env}"
  network     = google_compute_network.honeynet_vpc.self_link
  priority    = 0
  project     = var.project_id
}
# terraform import google_compute_route.dmz_to_core_cidr1 projects/${var.project_id}/global/routes/dmz-to-core1-${var.env}
