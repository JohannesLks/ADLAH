variable "cluster_vpc_self_link" {
  description = "The self_link of the cluster VPC network."
  type        = string
}

variable "core_vpc_self_link" {
  description = "The self_link of the core VPC network."
  type        = string
}

variable "honeynet_vpc_self_link" {
  description = "The self_link of the honeynet VPC network."
  type        = string
}

variable "cluster_subnet_cidr" {
  description = "The CIDR range for the cluster subnetwork."
  type        = string
}

variable "core_subnet_cidr" {
  description = "The CIDR range for the core subnetwork."
  type        = string
}

variable "core_subnet2_cidr" {
  description = "The CIDR range for the second core subnetwork."
  type        = string
}

variable "dmz_cidr" {
  description = "The CIDR range for the DMZ subnetwork."
  type        = string
}

variable "region" {
  description = "The Google Cloud region."
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