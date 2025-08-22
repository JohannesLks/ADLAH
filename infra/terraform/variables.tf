# Global variables for ADLAH Terraform

variable "project_id" {
  type    = string
  default = "adlah-staging"
}

variable "region" {
  type    = string
  default = "europe-west3"
}

variable "zone" {
  type    = string
  default = "europe-west3-a"
}

variable "env" {
  type    = string
  default = "prod"
}

# Network CIDRs
variable "dmz_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "core_subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "core_subnet2_cidr" {
  type    = string
  default = "10.1.0.0/24"
}

variable "cluster_subnet_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

# Optional static external IPs (pre-reserved). If null, Terraform will allocate a new one.
variable "bastion_static_ip" {
  type    = string
  default = null
}

variable "hive_static_ip" {
  type    = string
  default = null
}

# Internal IP overrides (optional). If empty string => let GCP auto assign.
variable "bastion_internal_ip" {
  type    = string
  default = "10.0.0.21"
}

variable "hive_internal_ip" {
  type    = string
  default = "10.1.0.10"
}

variable "cluster_core_ip" {
  type    = string
  default = "10.1.0.15"
}

variable "cluster_cluster_ip" {
  type    = string
  default = "10.2.0.15"
}

variable "sensor_core_ip" {
  type    = string
  default = "10.1.0.5"
}

variable "sensor_dmz_ip" {
  type    = string
  default = "10.0.0.5"
}

# Machine types & sizes
variable "bastion_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "hive_machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "cluster_machine_type" {
  type    = string
  default = "e2-custom-4-11008"
}

variable "sensor_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "bastion_disk_size_gb" {
  type    = number
  default = 40
}

variable "hive_disk_size_gb" {
  type    = number
  default = 100
}

variable "cluster_disk_size_gb" {
  type    = number
  default = 50
}

variable "sensor_disk_size_gb" {
  type    = number
  default = 50
}

# Firewall / networking helper vars
variable "iap_source_range" {
  type    = list(string)
  default = ["35.235.240.0/20"]
}

variable "internet_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

# Resource policies (e.g. snapshot schedules) attached to created disks
variable "resource_policy_ids" {
  type        = list(string)
  default     = []
  description = "List of resource policy self_links to attach to compute disks (snapshot schedules)."
}

# Image selection
variable "ubuntu_image_family" {
  type    = string
  default = "ubuntu-minimal-2204-lts"
}

variable "ubuntu_image_project" {
  type    = string
  default = "ubuntu-os-cloud"
}

# Service account override (if not provided, default GCE SA is used)
variable "compute_service_account_email" {
  type        = string
  default     = null
  description = "Custom service account email to attach to instances. If null, use the project's default compute service account."
}
