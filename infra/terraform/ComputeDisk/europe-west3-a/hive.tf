resource "google_compute_disk" "hive" {
  name    = "hive-${var.env}"
  project = var.project_id
  zone    = var.zone
  type    = "pd-balanced"
  size    = var.hive_disk_size_gb
  image   = data.google_compute_image.ubuntu_base.self_link
  labels  = { env = var.env }
  physical_block_size_bytes = 4096
  resource_policies         = var.resource_policy_ids
}
# terraform import google_compute_disk.hive projects/${var.project_id}/zones/${var.zone}/disks/hive
