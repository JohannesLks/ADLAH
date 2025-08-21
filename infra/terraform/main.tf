# This file calls all subdirectories as modules, so that Terraform can find
# and deploy the resources defined within them.

data "google_compute_image" "ubuntu" {
  family  = var.ubuntu_image_family
  project = var.ubuntu_image_project
}
module "compute_address" {
  source     = "./ComputeAddress"
  project_id = var.project_id
  region     = var.region
  env        = var.env
}

module "compute_disk" {
  source                 = "./ComputeDisk"
  project_id             = var.project_id
  zone                   = var.zone
  env                    = var.env
  ubuntu_image_self_link = data.google_compute_image.ubuntu.self_link
  bastion_disk_size_gb   = var.bastion_disk_size_gb
  hive_disk_size_gb      = var.hive_disk_size_gb
  cluster_disk_size_gb   = var.cluster_disk_size_gb
  sensor_disk_size_gb    = var.sensor_disk_size_gb
}

module "compute_firewall" {
  source                 = "./ComputeFirewall"
  project_id             = var.project_id
  env                    = var.env
  core_vpc_self_link     = module.compute_network.core_vpc_self_link
  honeynet_vpc_self_link = module.compute_network.honeynet_vpc_self_link
  iap_source_range       = var.iap_source_range
  internet_cidr          = var.internet_cidr
  bastion_internal_ip    = var.bastion_internal_ip
  hive_internal_ip       = var.hive_internal_ip
  sensor_core_ip         = var.sensor_core_ip
  sensor_dmz_ip          = var.sensor_dmz_ip
}

module "compute_instance" {
  source                        = "./ComputeInstance"
  project_id                    = var.project_id
  zone                          = var.zone
  env                           = var.env
  ubuntu_image_self_link        = data.google_compute_image.ubuntu.self_link
  core_vpc_self_link            = module.compute_network.core_vpc_self_link
  cluster_vpc_self_link         = module.compute_network.cluster_vpc_self_link
  honeynet_vpc_self_link        = module.compute_network.honeynet_vpc_self_link
  core_subnet2_self_link        = module.compute_subnetwork.core_subnet2_self_link
  dmz_subnet_self_link          = module.compute_subnetwork.dmz_subnet_self_link
  cluster_subnet_self_link      = module.compute_subnetwork.cluster_subnet_self_link
  bastion_address               = module.compute_address.bastion_address
  hive_external_address         = module.compute_address.hive_external_address
  bastion_internal_ip           = var.bastion_internal_ip
  hive_internal_ip              = var.hive_internal_ip
  cluster_core_ip               = var.cluster_core_ip
  cluster_cluster_ip            = var.cluster_cluster_ip
  sensor_core_ip                = var.sensor_core_ip
  sensor_dmz_ip                 = var.sensor_dmz_ip
  bastion_machine_type          = var.bastion_machine_type
  hive_machine_type             = var.hive_machine_type
  cluster_machine_type          = var.cluster_machine_type
  sensor_machine_type           = var.sensor_machine_type
  compute_service_account_email = var.compute_service_account_email
  bastion_disk_size_gb          = var.bastion_disk_size_gb
  hive_disk_size_gb             = var.hive_disk_size_gb
  cluster_disk_size_gb          = var.cluster_disk_size_gb
  sensor_disk_size_gb           = var.sensor_disk_size_gb
}

module "compute_network" {
  source     = "./ComputeNetwork"
  project_id = var.project_id
  env        = var.env
}

module "compute_route" {
  source                 = "./ComputeRoute"
  project_id             = var.project_id
  env                    = var.env
  core_vpc_self_link     = module.compute_network.core_vpc_self_link
  honeynet_vpc_self_link = module.compute_network.honeynet_vpc_self_link
  core_subnet_cidr       = var.core_subnet_cidr
  core_subnet2_cidr      = var.core_subnet2_cidr
  dmz_cidr               = var.dmz_cidr
  next_hop_peering       = "placeholder" # Replace with actual peering when ready
}

module "compute_subnetwork" {
  source                 = "./ComputeSubnetwork"
  project_id             = var.project_id
  region                 = var.region
  env                    = var.env
  core_vpc_self_link     = module.compute_network.core_vpc_self_link
  cluster_vpc_self_link  = module.compute_network.cluster_vpc_self_link
  honeynet_vpc_self_link = module.compute_network.honeynet_vpc_self_link
  dmz_cidr               = var.dmz_cidr
  core_subnet_cidr       = var.core_subnet_cidr
  core_subnet2_cidr      = var.core_subnet2_cidr
  cluster_subnet_cidr    = var.cluster_subnet_cidr
}