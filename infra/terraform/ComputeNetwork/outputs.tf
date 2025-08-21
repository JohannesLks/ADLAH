output "core_vpc_self_link" {
  description = "The self-link of the core VPC network"
  value       = google_compute_network.core_vpc.self_link
}

output "cluster_vpc_self_link" {
  description = "The self-link of the cluster VPC network"
  value       = google_compute_network.cluster_vpc.self_link
}

output "honeynet_vpc_self_link" {
  description = "The self-link of the honeynet VPC network"
  value       = google_compute_network.honeynet_vpc.self_link
}