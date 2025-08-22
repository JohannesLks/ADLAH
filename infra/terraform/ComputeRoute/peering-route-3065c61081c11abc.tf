resource "google_compute_route" "dmz_to_core_cidr2" {
  description = "Route dmz -> core subnet2"
  dest_range  = var.core_subnet2_cidr
  name        = "dmz-to-core2-${var.env}"
  network     = var.honeynet_vpc_self_link
  priority    = 0
  project          = var.project_id
  next_hop_gateway = "default-internet-gateway"
}
# legacy import reference updated: terraform import google_compute_route.dmz_to_core_cidr2 projects/${var.project_id}/global/routes/dmz-to-core2-${var.env}
