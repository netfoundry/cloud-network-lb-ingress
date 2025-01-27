variable "region" {}
variable "compartment_ocid" {}
variable "vcn_id" {}
variable "vcn_default_route_table_id" {}
variable "vcn_name" {}
variable "subnet_id" {}
variable "route_table_name" {}
variable "backend_set_policy" {
  default = "FIVE_TUPLE"
}
variable "lb_name_prefix" {
  default = "nf-lb"
}
variable "freeform_tag" {
  default = "terraform_nlb"
}
variable "backend_set_health_checker_interval_in_millis" {
  default =  10000
}
variable "backend_set_health_checker_retries" {
  default = 3
}
variable "backend_set_health_checker_timeout_in_millis" {
  default = 3000
}
variable "instance_ids" {}
variable "backend_weight" {
  default = 1
}
variable "backend_is_drain" {
  default = false
}
variable "backend_is_offline" {
  default = false
}
variable "backend_is_backup" {
  default = false
}
variable "availability_domain" {
  default = 3
}
variable "peerAddressPrefix" {}
variable "dns_svc_ip_range" {}
variable "er_sg1_id" {}