module "vcn1" {
  source         = "../modules/m-gcp-network"
  project        = var.project
  vcn_name       = var.vcn_name
  region         = var.region
  nf_subnet_cidr = var.nf_subnet_cidr
  create_vcn     = true
}

module "compute1" {
  depends_on = [
    module.vcn1
  ]
  source      = "../modules/m-gcp-compute"
  project     = var.project
  region      = var.region
  er_reg_keys = var.nf_router_registration_key_list
}

module "compute-test" {
  depends_on = [
    module.vcn1,
    module.compute1
  ]
  source = "../modules/m-gcp-compute"
  project              = var.project
  region               = var.region
  instance_name_prefix = "lb-test-vm"
}

module "nlb1" {
  depends_on = [
    module.compute1
  ]
  source   = "../modules/m-gcp-nlb"
  project  = var.project
  vcn_name = var.vcn_name
  region   = var.region
}


output "er_public_ips" {value = module.compute1.instance_public_ips}
output "er_private_ips" { value = module.compute1.instance_private_ips}
output "test_public_ips" {value = module.compute-test.instance_public_ips}
output "test_private_ips" { value = module.compute-test.instance_private_ips}