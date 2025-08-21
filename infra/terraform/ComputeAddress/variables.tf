variable "env" {
  description = "The deployment environment (e.g., 'dev', 'prod')."
  type        = string
}

variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "The Google Cloud region."
  type        = string
}

variable "bastion_static_ip" {
  description = "The static IP address for the bastion host."
  type        = string
  default     = null
}

variable "hive_static_ip" {
  description = "The static IP address for the hive host."
  type        = string
  default     = null
}