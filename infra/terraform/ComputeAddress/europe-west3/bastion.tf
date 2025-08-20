resource "google_compute_address" "bastion" {
  address      = "34.40.96.43"
  address_type = "EXTERNAL"

  labels = {
    managed-by-cnrm = "true"
  }

  name         = "bastion"
  network_tier = "PREMIUM"
  project      = "adlah3"
  region       = "europe-west3"
}
# terraform import google_compute_address.bastion projects/adlah3/regions/europe-west3/addresses/bastion
