resource "google_compute_disk" "bastion" {
  name    = "bastion-${var.env}"
  project = var.project_id
  zone    = var.zone
  type    = "pd-balanced"
  size    = var.bastion_disk_size_gb
  image   = data.google_compute_image.ubuntu_base.self_link
  labels  = { env = var.env }
  physical_block_size_bytes = 4096
  resource_policies         = var.resource_policy_ids
}
# terraform import google_compute_disk.bastion projects/${var.project_id}/zones/${var.zone}/disks/bastion
