output "bastion_address" {
  description = "The address of the bastion host"
  value       = google_compute_address.bastion.address
}

output "hive_external_address" {
  description = "The external address of the hive instance"
  value       = google_compute_address.hive_external.address
}