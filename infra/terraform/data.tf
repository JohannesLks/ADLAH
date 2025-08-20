data "google_compute_image" "ubuntu_base" {
  family  = var.ubuntu_image_family
  project = var.ubuntu_image_project
}

data "google_client_config" "current" {}

locals {
  compute_service_account_email = coalesce(
    var.compute_service_account_email,
    "${data.google_client_config.current.project_number}-compute@developer.gserviceaccount.com"
  )
}
