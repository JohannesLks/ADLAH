variable "honeynet_vpc_self_link" {
  description = "The self_link of the honeynet VPC network."
  type        = string
}

variable "core_vpc_self_link" {
  description = "The self_link of the core VPC network."
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

variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "env" {
  description = "The deployment environment (e.g., 'dev', 'prod')."
  type        = string
}

variable "next_hop_peering" {
  description = "The name of the next hop network peering."
  type        = string
}