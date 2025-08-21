output "cluster_subnet_self_link" {
  description = "The self-link of the cluster subnetwork"
  value       = google_compute_subnetwork.cluster_subnet.self_link
}

output "core_subnet_self_link" {
  description = "The self-link of the core subnetwork"
  value       = google_compute_subnetwork.core_subnet.self_link
}

output "core_subnet2_self_link" {
  description = "The self-link of the core subnetwork 2"
  value       = google_compute_subnetwork.core_subnet2.self_link
}

output "dmz_subnet_self_link" {
  description = "The self-link of the dmz subnetwork"
  value       = google_compute_subnetwork.dmz_subnet.self_link
}