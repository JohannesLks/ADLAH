resource "google_compute_route" "core_to_dmz" {
  description = "Route core -> dmz"
  dest_range  = var.dmz_cidr
  name        = "core-to-dmz-${var.env}"
  network     = google_compute_network.core_vpc.self_link
  priority    = 0
  project     = var.project_id
}
# terraform import google_compute_route.core_to_dmz projects/${var.project_id}/global/routes/core-to-dmz-${var.env}
