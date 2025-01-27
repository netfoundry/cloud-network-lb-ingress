module "vcn1" {
  source            = "../modules/m-oci-vcn"
  count             = var.include_m_oci_vcn ? 1 : 0
  region            = var.region
  vcn_name          = var.vcn_name
  vcn_cidr          = var.vcn_cidr
  subnet_cidr       = var.nf_subnet_cidr
  route_table_name  = var.route_table_name
  compartment_ocid  = var.compartment_id
}

module "compute1" {
  depends_on = [
    module.vcn1
  ]
  source            = "../modules/m-oci-compute"
  region            = var.region
  compartment_ocid  = var.compartment_id
  er_ssh_public_key = "~/.ssh/id_rsa.pub"
  vcn_name          = var.vcn_name
  route_table_name  = var.route_table_name
  subnet_cidr       = var.nf_subnet_cidr
  er_reg_keys       = var.nf_router_registration_key_list
  dns_svc_ip_range  = var.dns_svc_ip_range
  tunnel_ip         = "100.127.255.254"
}

module "nlb1" {
  depends_on = [
    module.compute1
  ]
  source                     = "../modules/m-oci-nlb"
  region                     = var.region
  compartment_ocid           = var.compartment_id
  vcn_id                     = module.compute1.vcn_id
  vcn_name                   = var.vcn_name
  subnet_id                  = module.compute1.subnet_id
  route_table_name           = var.route_table_name
  instance_ids               = module.compute1.instance_ids
  er_sg1_id                  = module.compute1.er_sg1_id
  peerAddressPrefix          = var.peerAddressPrefix
  dns_svc_ip_range           = var.dns_svc_ip_range
  vcn_default_route_table_id = module.compute1.vcn_default_route_table_id
}

module "compute_test" {
  depends_on = [
    module.vcn1
  ]
  source               = "../modules/m-oci-compute"
  region               = var.region
  compartment_ocid     = var.compartment_id
  er_ssh_public_key    = "~/.ssh/id_rsa.pub"
  vcn_name             = var.vcn_name
  route_table_name     = var.route_table_name
  subnet_cidr          = var.nf_subnet_cidr
  instance_name_prefix = "test-vm"
}


output "er_private_ips" {value = module.compute1.instance_private_ips}
output "er_public_ips" {value = module.compute1.instance_public_ips}
output "test_private_ips" {value = module.compute_test.instance_private_ips}
output "test_public_ips" {value = module.compute_test.instance_public_ips}