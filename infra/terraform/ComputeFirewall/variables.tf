variable "core_vpc_self_link" {
  description = "The self_link of the core VPC network."
  type        = string
}

variable "honeynet_vpc_self_link" {
  description = "The self_link of the honeynet VPC network."
  type        = string
}

variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "env" {
  description = "The deployment environment (e.g., 'dev', 'prod')."
  type        = string
}

variable "internet_cidr" {
  description = "The CIDR range for the public internet."
  type        = string
}

variable "iap_source_range" {
  description = "The source range for IAP SSH access."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

variable "bastion_internal_ip" {
  description = "The internal IP address of the bastion host."
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