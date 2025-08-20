resource "google_compute_address" "hive_external" {
  address      = "34.40.80.159"
  address_type = "EXTERNAL"

  labels = {
    managed-by-cnrm = "true"
  }

  name         = "hive-external"
  network_tier = "PREMIUM"
  project      = "adlah3"
  region       = "europe-west3"
}
# terraform import google_compute_address.hive_external projects/adlah3/regions/europe-west3/addresses/hive-external
