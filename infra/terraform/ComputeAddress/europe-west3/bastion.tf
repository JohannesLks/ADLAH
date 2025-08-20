resource "google_compute_address" "bastion" {
  address_type = "EXTERNAL"
  name         = "bastion-${var.env}"
  network_tier = "PREMIUM"
  project      = var.project_id
  region       = var.region

  labels = {
    env = var.env
  }
  # no 'address' specified -> new static IP will be reserved automatically
}

# Optional: use a pre-reserved static IP if provided
resource "google_compute_address" "bastion_fixed" {
  count        = var.bastion_static_ip == null ? 0 : 1
  address      = var.bastion_static_ip
  address_type = "EXTERNAL"
  name         = "bastion-fixed-${var.env}"
  network_tier = "PREMIUM"
  project      = var.project_id
  region       = var.region
  labels = {
    env    = var.env
    source = "provided"
  }
}

# Legacy import reference (update project/region manually if using import)
# terraform import google_compute_address.bastion projects/${var.project_id}/regions/${var.region}/addresses/bastion
