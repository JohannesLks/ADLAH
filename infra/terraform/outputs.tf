output "bastion_external_ip" {
  value       = coalesce(try(google_compute_address.bastion_fixed[0].address, null), try(google_compute_address.bastion.address, null))
  description = "External IP of the bastion host"
}

output "hive_external_ip" {
  value       = coalesce(try(google_compute_address.hive_fixed[0].address, null), try(google_compute_address.hive_external.address, null))
  description = "External IP of the hive host"
}

output "bastion_internal_ip" {
  value       = try(google_compute_instance.bastion.network_interface[0].network_ip, null)
  description = "Internal IP of bastion"
}
output "hive_internal_ip" {
  value       = try(google_compute_instance.hive.network_interface[0].network_ip, null)
  description = "Internal IP of hive"
}
output "cluster_core_ip" {
  value       = try(google_compute_instance.cluster.network_interface[0].network_ip, null)
  description = "Cluster core network IP"
}
output "cluster_cluster_ip" {
  value       = try(google_compute_instance.cluster.network_interface[1].network_ip, null)
  description = "Cluster second network IP"
}
output "sensor_core_ip" {
  value       = try(google_compute_instance.sensor.network_interface[0].network_ip, null)
  description = "Sensor core network IP"
}
output "sensor_dmz_ip" {
  value       = try(google_compute_instance.sensor.network_interface[1].network_ip, null)
  description = "Sensor dmz network IP"
}

output "core_vpc_name" {
  value       = google_compute_network.core_vpc.name
  description = "Core VPC name"
}
output "honeynet_vpc_name" {
  value       = google_compute_network.honeynet_vpc.name
  description = "Honeynet VPC name"
}
output "cluster_vpc_name" {
  value       = google_compute_network.cluster_vpc.name
  description = "Cluster VPC name"
}
