variable "env" {
  description = "The deployment environment (e.g., 'dev', 'prod')."
  type        = string
}

variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "zone" {
  description = "The Google Cloud zone."
  type        = string
}

variable "bastion_machine_type" {
  description = "The machine type for the bastion instance."
  type        = string
}

variable "cluster_machine_type" {
  description = "The machine type for the cluster instance."
  type        = string
}

variable "hive_machine_type" {
  description = "The machine type for the hive instance."
  type        = string
}

variable "sensor_machine_type" {
  description = "The machine type for the sensor instance."
  type        = string
}

variable "ubuntu_image_self_link" {
  description = "The self_link of the Ubuntu base image."
  type        = string
}

variable "bastion_disk_size_gb" {
  description = "The size of the bastion disk in GB."
  type        = number
}

variable "cluster_disk_size_gb" {
  description = "The size of the cluster disk in GB."
  type        = number
}

variable "hive_disk_size_gb" {
  description = "The size of the hive disk in GB."
  type        = number
}

variable "sensor_disk_size_gb" {
  description = "The size of the sensor disk in GB."
  type        = number
}

variable "bastion_fixed_address" {
  description = "The fixed IP address for the bastion host."
  type        = string
  default     = null
}

variable "bastion_address" {
  description = "The IP address for the bastion host."
  type        = string
}

variable "honeynet_vpc_self_link" {
  description = "The self_link of the honeynet VPC network."
  type        = string
}

variable "dmz_subnet_self_link" {
  description = "The self_link of the DMZ subnetwork."
  type        = string
}

variable "bastion_internal_ip" {
  description = "The internal IP address of the bastion host."
  type        = string
}

variable "compute_service_account_email" {
  description = "The email address of the compute service account."
  type        = string
}

variable "core_vpc_self_link" {
  description = "The self_link of the core VPC network."
  type        = string
}

variable "core_subnet2_self_link" {
  description = "The self_link of the second core subnetwork."
  type        = string
}

variable "cluster_core_ip" {
  description = "The core IP address of the cluster."
  type        = string
}

variable "cluster_vpc_self_link" {
  description = "The self_link of the cluster VPC network."
  type        = string
}

variable "cluster_subnet_self_link" {
  description = "The self_link of the cluster subnetwork."
  type        = string
}

variable "cluster_cluster_ip" {
  description = "The cluster IP address of the cluster."
  type        = string
}

variable "hive_fixed_address" {
  description = "The fixed IP address for the hive host."
  type        = string
  default     = null
}

variable "hive_external_address" {
  description = "The external IP address for the hive host."
  type        = string
}

variable "hive_internal_ip" {
  description = "The internal IP address of the hive host."
  type        = string
}

variable "sensor_core_ip" {
  description = "The core network IP address of the sensor."
  type        = string
}

variable "sensor_dmz_ip" {
  description = "The DMZ network IP address of the sensor."
  type        = string
}