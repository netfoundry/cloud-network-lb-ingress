variable "region" {}
variable "compartment_id" {}
variable "vcn_name" {}
variable "nf_subnet_cidr" {}
variable "route_table_name" {}
variable "include_m_oci_vcn" {
  default = false
}
variable "vcn_cidr" {
  default = ""
}
variable "nf_router_registration_key_list" {}

module "vcn1" {
  source = "../modules/m-oci-vcn"
  count = var.include_m_oci_vcn ? 1 : 0
  region = var.region
  vcn_name = var.vcn_name
  vcn_cidr = var.vcn_cidr
  route_table_name = var.route_table_name
  compartment_ocid = var.compartment_id
}

module "compute1" {
  depends_on = [
    module.vcn1
  ]
  source = "../modules/m-oci-compute"
  region = var.region
  compartment_ocid = var.compartment_id
  er_ssh_public_key = "~/.ssh/id_rsa.pub"
  vcn_name = var.vcn_name
  route_table_name = var.route_table_name
  subnet_cidr = var.nf_subnet_cidr
  er_reg_keys = var.nf_router_registration_key_list
}

module "nlb1" {
  depends_on = [
    module.compute1
  ]
  source = "../modules/m-oci-nlb"
  region = var.region
  compartment_ocid = var.compartment_id
  vcn_id = module.compute1.vcn_id
  subnet_id = module.compute1.subnet_id
  route_table_name = var.route_table_name
  instance_ids = module.compute1.instance_ids
}


output "instance_private_ips" {value = module.compute1.instance_private_ips}
output "instance_public_ips" {value = module.compute1.instance_public_ips}