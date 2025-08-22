resource "google_compute_route" "dmz_to_core_cidr1" {
  description = "Route dmz -> core subnet1"
  dest_range  = var.core_subnet_cidr
  name        = "dmz-to-core1-${var.env}"
  network     = var.honeynet_vpc_self_link
  priority    = 0
  project          = var.project_id
  next_hop_gateway = "default-internet-gateway"
}
# terraform import google_compute_route.dmz_to_core_cidr1 projects/${var.project_id}/global/routes/dmz-to-core1-${var.env}
