resource "google_compute_address" "hive_external" {
  address_type = "EXTERNAL"
  name         = "hive-external-${var.env}"
  network_tier = "PREMIUM"
  project      = var.project_id
  region       = var.region
  labels = {
    env = var.env
  }
}

resource "google_compute_address" "hive_fixed" {
  count        = var.hive_static_ip == null ? 0 : 1
  address      = var.hive_static_ip
  address_type = "EXTERNAL"
  name         = "hive-fixed-${var.env}"
  network_tier = "PREMIUM"
  project      = var.project_id
  region       = var.region
  labels = {
    env    = var.env
    source = "provided"
  }
}

# terraform import google_compute_address.hive_external projects/${var.project_id}/regions/${var.region}/addresses/hive-external
