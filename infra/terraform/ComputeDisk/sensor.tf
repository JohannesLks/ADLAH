resource "google_compute_disk" "sensor" {
  name                      = "sensor-${var.env}"
  project                   = var.project_id
  zone                      = var.zone
  type                      = "pd-balanced"
  size                      = var.sensor_disk_size_gb
  image                     = var.ubuntu_image_self_link
  labels                    = { env = var.env }
  physical_block_size_bytes = 4096
}
# terraform import google_compute_disk.sensor projects/${var.project_id}/zones/${var.zone}/disks/sensor
