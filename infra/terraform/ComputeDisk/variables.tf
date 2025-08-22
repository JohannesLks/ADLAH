variable "ubuntu_image_self_link" {
  description = "The self_link of the Ubuntu base image."
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

variable "env" {
  description = "The deployment environment (e.g., 'dev', 'prod')."
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