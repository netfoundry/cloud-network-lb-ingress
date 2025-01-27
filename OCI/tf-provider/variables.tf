variable "region" {}
variable "compartment_id" {}
variable "vcn_name" {}
variable "nf_subnet_cidr" {}
variable "route_table_name" {
  default = ""
}
variable "include_m_oci_vcn" {
  default = false
}
variable "vcn_cidr" {
  default = ""
}
variable "nf_router_registration_key_list" {}
variable "dns_svc_ip_range" {
  default = ["100.64.0.0/13","100.72.0.0/13"]
}
variable "peerAddressPrefix" { 
  default = "10.17.0.0/24"
}
